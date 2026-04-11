import { setGlobalOptions } from "firebase-functions/v2";
import { onCall, HttpsError } from "firebase-functions/v2/https";
import { defineSecret } from "firebase-functions/params";
import * as logger from "firebase-functions/logger";
import * as crypto from "crypto";

import * as admin from "firebase-admin";
import { SESClient, SendEmailCommand } from "@aws-sdk/client-ses";

admin.initializeApp();
const db = admin.firestore();

setGlobalOptions({ maxInstances: 10, region: "europe-north1" });

const AWS_ACCESS_KEY_ID = defineSecret("AWS_ACCESS_KEY_ID");
const AWS_SECRET_ACCESS_KEY = defineSecret("AWS_SECRET_ACCESS_KEY");
const SES_FROM_EMAIL = defineSecret("SES_FROM_EMAIL");
const SES_REGION = "eu-north-1"; // AWS SES Stockholm

const ALLOWED_TTLS = [60, 120, 300, 600] as const;

function normalizeTtl(ttlSeconds: number): number {
  if (!Number.isFinite(ttlSeconds)) return 60;
  const rounded = Math.floor(ttlSeconds);
  return (ALLOWED_TTLS as readonly number[]).includes(rounded) ? rounded : 60;
}

function otpDocId(email: string): string {
  return crypto.createHash("sha256").update(email.trim().toLowerCase()).digest("hex");
}

function generateOtp4(): string {
  const n = crypto.randomInt(0, 10000);
  return n.toString().padStart(4, "0");
}

function hashOtp(otp: string, salt: string): string {
  return crypto.createHash("sha256").update(`${otp}:${salt}`).digest("hex");
}

function createSesClient(): SESClient {
  const accessKeyId = AWS_ACCESS_KEY_ID.value();
  const secretAccessKey = AWS_SECRET_ACCESS_KEY.value();

  if (!accessKeyId) throw new HttpsError("failed-precondition", "AWS_ACCESS_KEY_ID missing");
  if (!secretAccessKey) throw new HttpsError("failed-precondition", "AWS_SECRET_ACCESS_KEY missing");

  return new SESClient({
    region: SES_REGION,
    credentials: { accessKeyId, secretAccessKey },
  });
}

async function sendEmail(
  to: string,
  subject: string,
  text: string,
  html: string
): Promise<void> {
  const from = SES_FROM_EMAIL.value();
  if (!from) throw new HttpsError("failed-precondition", "SES_FROM_EMAIL missing");

  const ses = createSesClient();
  await ses.send(
    new SendEmailCommand({
      Destination: { ToAddresses: [to] },
      Source: from,
      Message: {
        Subject: { Charset: "UTF-8", Data: subject },
        Body: {
          Text: { Charset: "UTF-8", Data: text },
          Html: { Charset: "UTF-8", Data: html },
        },
      },
    })
  );
}

/* ====== Send test email ====== */
/* ============================ */
export const sendTestEmail = onCall(
  { secrets: [AWS_ACCESS_KEY_ID, AWS_SECRET_ACCESS_KEY, SES_FROM_EMAIL] },
  async (request) => {
    try {
      const data = request.data as { email?: string; ttlSeconds?: number };

      const email = (data.email ?? "").trim().toLowerCase();
      if (!email) throw new HttpsError("invalid-argument", "email is required");

      await sendEmail(
        email,
        "Amazon SES test from Firebase Functions",
        "If you received this email, Amazon SES is working.",
        `<p>If you received this email, <b>Amazon SES is working</b>. email data is ${email}</p>`
      );

      logger.info("Test email sent", { email });
      return { ok: true };
    } catch (err: any) {
      logger.error("sendTestEmail failed", {
        message: err?.message,
        code: err?.code,
      });

      if (err instanceof HttpsError) throw err;

      throw new HttpsError("internal", err?.message ?? "Unknown error");
    }
  }
);

/* ====== Send email OTP ====== */
/* ============================ */
export const sendEmailOtp = onCall(
  {
    secrets: [AWS_ACCESS_KEY_ID, AWS_SECRET_ACCESS_KEY, SES_FROM_EMAIL],
  },
  async (request) => {
      try {
    const data = request.data as { email?: string; ttlSeconds?: number };

    const email = (data.email ?? "").trim().toLowerCase();
    if (!email) throw new HttpsError("invalid-argument", "email is required");

    const ttlSeconds = normalizeTtl(Number(data.ttlSeconds ?? 60)); // ?

    const docId = otpDocId(email); // ?
    const ref = db.collection("email_otp").doc(docId); // ?

    const now = admin.firestore.Timestamp.now();

    logger.info("OTP: about to read doc", { docId });

    let existing;
    try {
      existing = await ref.get();
    } catch (e: any) {
      logger.error("Firestore read failed", { message: e?.message, code: e?.code });
      throw new HttpsError("internal", "Firestore read failed");
    }

    if (existing.exists) {
      const sentAt = existing.get("sentAt") as admin.firestore.Timestamp | undefined;
      if (sentAt) {
        const secondsSince = now.seconds - sentAt.seconds;
        if (secondsSince < 5) {
          throw new HttpsError("resource-exhausted", "Please wait a moment before resending.");
        }
      }
    }

    const otp = generateOtp4();
    const salt = crypto.randomBytes(16).toString("hex");
    const otpHash = hashOtp(otp, salt);

    const expiresAt = admin.firestore.Timestamp.fromMillis(Date.now() + ttlSeconds * 1000);
    logger.info("OTP: about to write doc", { docId });

    try {
        await ref.set(
          {
            email,
            otpHash,
            otpSalt: salt,
            expiresAt,
            sentAt: now,
            attempts: 0,
            ttlSeconds,
          },
          { merge: true }
        );
    } catch (e: any) {
      logger.error("Firestore write failed", { message: e?.message, code: e?.code });
      throw new HttpsError("internal", "Firestore write failed");
    }

      const minutes = Math.ceil(ttlSeconds / 60);

      await sendEmail(
        email,
        "Your verification code",
        `Your OTP code is ${otp}. It expires in ${minutes} minute(s).`,
        `
          <div style="font-family: Arial, sans-serif; line-height: 1.4;">
            <p>Your OTP code is:</p>
            <p style="font-size: 28px; font-weight: bold; letter-spacing: 4px;">${otp}</p>
            <p>This code expires in <b>${minutes} minute(s)</b>.</p>
            <p>If you didn’t request this, you can ignore this email.</p>
          </div>
        `
      );

      logger.info("OTP email sent", { email, ttlSeconds });
      return { ok: true, ttlSeconds };
    } catch (err: any) {
      logger.error("SES OTP send failed", {
        message: err?.message,
        code: err?.code,
      });
      throw new HttpsError("internal", "Failed to send OTP email");
    }
  }
);

/* ====== Verify email OTP ====== */
/* ============================== */
export const verifyEmailOtp = onCall(async (request) => {
  const data = request.data as { email?: string; otp?: string };

  const email = (data.email ?? "").trim().toLowerCase();
  const otp = (data.otp ?? "").trim();

  if (!email) throw new HttpsError("invalid-argument", "email is required");
  if (!otp) throw new HttpsError("invalid-argument", "otp is required");
  if (!/^\d{4}$/.test(otp)) throw new HttpsError("invalid-argument", "otp must be 4 digits");

  const docId = otpDocId(email);
  const ref = db.collection("email_otp").doc(docId);

  const snap = await ref.get();
  if (!snap.exists) return { valid: false };

  const expiresAt = snap.get("expiresAt") as admin.firestore.Timestamp | undefined;
  const salt = snap.get("otpSalt") as string | undefined;
  const storedHash = snap.get("otpHash") as string | undefined;
  const attempts = (snap.get("attempts") as number | undefined) ?? 0;

  if (!expiresAt || !salt || !storedHash) return { valid: false };

  if (attempts >= 10) {
    throw new HttpsError("resource-exhausted", "Too many attempts. Please resend OTP.");
  }

  if (expiresAt.toMillis() <= Date.now()) {
    return { valid: false, reason: "expired" };
  }

  const computed = hashOtp(otp, salt);

  let isValid = false;
  try {
    isValid = crypto.timingSafeEqual(
      Buffer.from(computed, "hex"),
      Buffer.from(storedHash, "hex")
    );
  } catch {
    isValid = false;
  }

  await ref.set({ attempts: attempts + 1 }, { merge: true });

  if (!isValid) return { valid: false };

  await ref.delete();
  return { valid: true };
});

// ===== /* Token configuration */ =====
const RESET_TOKEN_TTL_SECONDS = 15 * 60;
const RESET_MAX_ATTEMPTS = 10;

function generateResetToken(): string {
    return crypto.randomBytes(32).toString("hex")
}

function tokenDocId(token: string): string {
    // doc id derived from token (not reversible)
    return crypto.createHash("sha256").update(token).digest("hex")
}

function hashToken(token:string, salt: string): string {
    return crypto.createHash("sha256").update(`${token}:${salt}`).digest("hex")
}

function isStrongPassword(pw: string): boolean {
  if (!pw || pw.length < 8) return false;

  let lower = 0, upper = 0, digit = 0, special = 0;
  for (const ch of pw) {
    if (ch >= "a" && ch <= "z") lower++;
    else if (ch >= "A" && ch <= "Z") upper++;
    else if (ch >= "0" && ch <= "9") digit++;
    else special++;
  }
  return lower >= 2 && upper >= 2 && digit >= 1 && special >= 1;
}

/* ====== Send reset password link ====== */
/* ====================================== */
export const requestPasswordResetLink = onCall(
  { secrets: [AWS_ACCESS_KEY_ID, AWS_SECRET_ACCESS_KEY, SES_FROM_EMAIL] },
  async (request) => {
    try {
      const data = request.data as { email?: string };
      const email = (data.email ?? "").trim().toLowerCase();
      if (!email) throw new HttpsError("invalid-argument", "email is required");

      // 1) Check email exists in Firestore (you can adjust collection name/field)
      const userSnap = await db
        .collection("users")
        .where("email", "==", email)
        .limit(1)
        .get();

      // IMPORTANT: do not leak whether user exists
      // If user not found, return ok anyway (prevents enumeration attacks)
      if (userSnap.empty) {
        return { ok: true };
      }

      // Optional: also ensure user exists in Firebase Auth
      // If Firestore is correct, Auth should exist too, but we keep it safe.
      try {
        await admin.auth().getUserByEmail(email);
      } catch {
        return { ok: true };
      }

      // 2) Basic rate-limit per email (avoid spamming)
      const rlRef = db.collection("password_reset_rate").doc(otpDocId(email));
      const now = admin.firestore.Timestamp.now();
      const rlDoc = await rlRef.get();

      if (rlDoc.exists) {
        const sentAt = rlDoc.get("sentAt") as admin.firestore.Timestamp | undefined;
        if (sentAt) {
          const secondsSince = now.seconds - sentAt.seconds;
          if (secondsSince < 10) {
            throw new HttpsError("resource-exhausted", "Please wait before resending.");
          }
        }
      }

      // 3) Create token record (store only hashed token)
      const token = generateResetToken();
      const salt = crypto.randomBytes(16).toString("hex");
      const tokenHash = hashToken(token, salt);

      const expiresAt = admin.firestore.Timestamp.fromMillis(
        Date.now() + RESET_TOKEN_TTL_SECONDS * 1000
      );

      const tokenId = tokenDocId(token);
      const tokenRef = db.collection("password_reset_tokens").doc(tokenId);

      await tokenRef.set(
        {
          email,
          tokenHash,
          tokenSalt: salt,
          expiresAt,
          createdAt: now,
          attempts: 0,
          used: false,
        },
        { merge: false }
      );

      await rlRef.set({ sentAt: now }, { merge: true });

      // 4) Send email with deep link
      const redirectLink = `https://inventory-app-352dc.web.app/reset?token=${encodeURIComponent(token)}`;
      const minutes = Math.ceil(RESET_TOKEN_TTL_SECONDS / 60);

      await sendEmail(
        email,
        "Reset your password",
        `Tap to reset your password: ${redirectLink} (expires in ${minutes} minutes).`,
        `
          <div style="font-family: Arial, sans-serif; line-height: 1.5;">
            <p>Tap the button below to reset your password:</p>
            <p>
              <a href="${redirectLink}"
                 style="display:inline-block;padding:12px 18px;background:#f5d400;color:#000;text-decoration:none;border-radius:10px;font-weight:bold;">
                Reset Password
              </a>
            </p>
            <p>This link expires in <b>${minutes} minutes</b>.</p>
            <p>If the button doesn’t work, copy and paste this link into your phone browser:</p>
            <p style="word-break: break-all;">${redirectLink}</p>
          </div>
        `
      );

      return { ok: true };
    } catch (err: any) {
      logger.error("requestPasswordResetLink failed", {
        message: err?.message,
        code: err?.code,
      });

      if (err instanceof HttpsError) throw err;
      throw new HttpsError("internal", err?.message ?? "Unknown error");
    }
  }
);

/* ====== Reset password with token ====== */
/* ======================================= */
export const resetPasswordWithToken = onCall(async (request) => {
  try {
    const data = request.data as { token?: string; newPassword?: string };

    const token = (data.token ?? "").trim();
    const newPassword = String(data.newPassword ?? "");

    if (!token) throw new HttpsError("invalid-argument", "token is required");
    if (!newPassword) throw new HttpsError("invalid-argument", "newPassword is required");

    if (!isStrongPassword(newPassword)) {
      throw new HttpsError("invalid-argument", "Password does not meet requirements.");
    }

    const id = tokenDocId(token);
    const ref = db.collection("password_reset_tokens").doc(id);
    const snap = await ref.get();

    if (!snap.exists) {
      return { ok: false, reason: "invalid" };
    }

    const expiresAt = snap.get("expiresAt") as admin.firestore.Timestamp | undefined;
    const salt = snap.get("tokenSalt") as string | undefined;
    const storedHash = snap.get("tokenHash") as string | undefined;
    const attempts = (snap.get("attempts") as number | undefined) ?? 0;
    const used = (snap.get("used") as boolean | undefined) ?? false;
    const email = (snap.get("email") as string | undefined) ?? "";

    if (!expiresAt || !salt || !storedHash || !email) return { ok: false, reason: "invalid" };
    if (used) return { ok: false, reason: "used" };

    if (attempts >= RESET_MAX_ATTEMPTS) {
      throw new HttpsError("resource-exhausted", "Too many attempts. Request a new reset email.");
    }

    if (expiresAt.toMillis() <= Date.now()) {
      return { ok: false, reason: "expired" };
    }

    const computed = hashToken(token, salt);

    let isValid = false;
    try {
      isValid = crypto.timingSafeEqual(
        Buffer.from(computed, "hex"),
        Buffer.from(storedHash, "hex")
      );
    } catch {
      isValid = false;
    }

    await ref.set({ attempts: attempts + 1 }, { merge: true });
    if (!isValid) return { ok: false, reason: "invalid" };

    // Update password in Firebase Auth
    const user = await admin.auth().getUserByEmail(email);
    await admin.auth().updateUser(user.uid, { password: newPassword });

    // Invalidate token
    await ref.set({ used: true }, { merge: true });
    await ref.delete();

    return { ok: true };
  } catch (err: any) {
    logger.error("resetPasswordWithToken failed", { message: err?.message, code: err?.code });
    if (err instanceof HttpsError) throw err;
    throw new HttpsError("internal", err?.message ?? "Unknown error");
  }
});

/* ====== Register new user ====== */
/* ================================ */
export const registerUser = onCall(async (request) => {
  try {
    const data = request.data as { email?: string; name?: string; password?: string };

    const email    = (data.email    ?? "").trim().toLowerCase();
    const name     = (data.name     ?? "").trim();
    const password = (data.password ?? "").trim();

    if (!email)    throw new HttpsError("invalid-argument", "email is required");
    if (!name)     throw new HttpsError("invalid-argument", "name is required");
    if (!password) throw new HttpsError("invalid-argument", "password is required");

    if (!isStrongPassword(password))
      throw new HttpsError("invalid-argument", "Password does not meet requirements.");

    // Prevent duplicate accounts — getUserByEmail throws auth/user-not-found if absent
    try {
      await admin.auth().getUserByEmail(email);
      // If we reach here, the user already exists
      throw new HttpsError("already-exists", "An account with this email already exists.");
    } catch (err: any) {
      if (err instanceof HttpsError) throw err;
      // auth/user-not-found is expected — continue to create the user
    }

    const userRecord = await admin.auth().createUser({
      email,
      password,
      displayName: name,
    });

    await db.collection("users").doc(userRecord.uid).set({
      uid: userRecord.uid,
      email,
      displayName: name,
      role: "staff",
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
    });

    logger.info("User registered", { uid: userRecord.uid, email });
    return { ok: true, uid: userRecord.uid };

  } catch (err: any) {
    logger.error("registerUser failed", { message: err?.message, code: err?.code });
    if (err instanceof HttpsError) throw err;
    throw new HttpsError("internal", err?.message ?? "Unknown error");
  }
});

