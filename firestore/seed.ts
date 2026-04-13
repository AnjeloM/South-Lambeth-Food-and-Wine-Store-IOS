/**
 * firestore/seed.ts
 *
 * Firebase Admin SDK seed script for South Lambeth Food & Wine Store.
 *
 * Usage:
 *   npm run seed                     — write all collections
 *   npm run seed -- --dry-run        — preview writes, no Firestore mutations
 *   npm run seed -- --clear          — delete all existing docs first, then seed
 *
 * Authentication (pick one):
 *   1. Set GOOGLE_APPLICATION_CREDENTIALS=/path/to/serviceAccount.json
 *   2. Run `gcloud auth application-default login` (uses ADC)
 */

import * as admin from "firebase-admin";
import { Firestore, Timestamp, WriteBatch } from "firebase-admin/firestore";
import * as fs from "fs";
import * as path from "path";

// ─── CLI flags ───────────────────────────────────────────────────────────────

const args = process.argv.slice(2);
const DRY_RUN = args.includes("--dry-run");
const CLEAR_FIRST = args.includes("--clear");

// ─── Firebase init ───────────────────────────────────────────────────────────

const serviceAccountPath = process.env.GOOGLE_APPLICATION_CREDENTIALS;

if (serviceAccountPath && fs.existsSync(serviceAccountPath)) {
  const serviceAccount = JSON.parse(
    fs.readFileSync(serviceAccountPath, "utf8")
  );
  admin.initializeApp({
    credential: admin.credential.cert(serviceAccount),
  });
} else {
  // Falls back to Application Default Credentials (gcloud auth application-default login)
  admin.initializeApp();
}

const db: Firestore = admin.firestore();

// ─── Schema configuration ────────────────────────────────────────────────────
//
// Derived directly from firestore_schema_spec.json.
// timestampFields      — always converted from ISO string → Firestore Timestamp
// nullableTimestampFields — same conversion, but null values are preserved as-is

interface CollectionConfig {
  idField: string;
  timestampFields: string[];
  nullableTimestampFields: string[];
}

const COLLECTION_CONFIG: Record<string, CollectionConfig> = {
  users: {
    idField: "userID",
    timestampFields: ["createdAt", "updatedAt"],
    nullableTimestampFields: [],
  },
  shops: {
    idField: "shopID",
    timestampFields: ["createdAt", "updatedAt"],
    nullableTimestampFields: [],
  },
  pendingRequests: {
    idField: "requestID",
    timestampFields: ["requestedAt"],
    nullableTimestampFields: ["approvedAt"],
  },
  employees: {
    idField: "employeeID",
    timestampFields: ["createdAt", "updatedAt"],
    nullableTimestampFields: [],
  },
  items: {
    idField: "itemID",
    timestampFields: [],
    nullableTimestampFields: [],
  },
  inventory: {
    idField: "inventoryID",
    timestampFields: ["updatedAt"],
    nullableTimestampFields: [],
  },
  purchaseRequests: {
    idField: "requestID",
    timestampFields: ["requestedAt"],
    nullableTimestampFields: ["approvedAt"],
  },
  timesheets: {
    idField: "timesheetID",
    timestampFields: ["createdAt"],
    // date / checkIn / checkOut are plain strings — intentionally not converted
    nullableTimestampFields: [],
  },
  notifications: {
    idField: "notificationID",
    timestampFields: ["createdAt"],
    nullableTimestampFields: ["readAt"],
  },
};

// ─── Helper: ISO string → Firestore Timestamp ────────────────────────────────

function isoToTimestamp(iso: string): Timestamp {
  return Timestamp.fromDate(new Date(iso));
}

// ─── Helper: apply timestamp conversions to a raw seed document ─────────────

function prepareDocument(
  raw: Record<string, unknown>,
  config: CollectionConfig
): Record<string, unknown> {
  const doc: Record<string, unknown> = { ...raw };

  for (const field of config.timestampFields) {
    if (field in doc) {
      const val = doc[field];
      if (typeof val === "string") {
        doc[field] = isoToTimestamp(val);
      }
    }
  }

  for (const field of config.nullableTimestampFields) {
    if (field in doc) {
      const val = doc[field];
      if (val === null) {
        doc[field] = null; // preserve null explicitly
      } else if (typeof val === "string") {
        doc[field] = isoToTimestamp(val);
      }
    }
  }

  return doc;
}

// ─── Helper: delete all documents in a collection ───────────────────────────

async function clearCollection(collectionName: string): Promise<void> {
  const snapshot = await db.collection(collectionName).get();
  if (snapshot.empty) return;

  // Firestore batch limit: 500 ops
  const chunks = chunkArray(snapshot.docs, 500);
  for (const chunk of chunks) {
    const batch: WriteBatch = db.batch();
    for (const doc of chunk) {
      batch.delete(doc.ref);
    }
    await batch.commit();
  }
  console.log(`  ✓ Cleared ${snapshot.size} existing docs from '${collectionName}'`);
}

// ─── Helper: split array into fixed-size chunks ─────────────────────────────

function chunkArray<T>(arr: T[], size: number): T[][] {
  const chunks: T[][] = [];
  for (let i = 0; i < arr.length; i += size) {
    chunks.push(arr.slice(i, i + size));
  }
  return chunks;
}

// ─── Core: seed one collection ───────────────────────────────────────────────

async function seedCollection(
  collectionName: string,
  documents: Record<string, unknown>[],
  config: CollectionConfig
): Promise<void> {
  if (documents.length === 0) {
    console.log(`  — Skipping '${collectionName}': no documents in seed data`);
    return;
  }

  if (CLEAR_FIRST) {
    await clearCollection(collectionName);
  }

  const chunks = chunkArray(documents, 500);

  for (const chunk of chunks) {
    if (!DRY_RUN) {
      const batch: WriteBatch = db.batch();
      for (const raw of chunk) {
        const docId = raw[config.idField] as string;
        if (!docId) {
          throw new Error(
            `Missing idField '${config.idField}' in document: ${JSON.stringify(raw)}`
          );
        }
        const prepared = prepareDocument(raw, config);
        const ref = db.collection(collectionName).doc(docId);
        batch.set(ref, prepared);
      }
      await batch.commit();
    }
  }

  const label = DRY_RUN ? "(dry-run) would write" : "Wrote";
  console.log(`  ✓ ${label} ${documents.length} doc(s) → '${collectionName}'`);

  if (DRY_RUN) {
    // Print a preview of the first document with timestamps resolved
    const preview = prepareDocument(documents[0], config);
    console.log(`    Preview of first doc (${config.idField}=${documents[0][config.idField]}):`);
    for (const [k, v] of Object.entries(preview)) {
      const display = v instanceof Timestamp
        ? `Timestamp(${v.toDate().toISOString()})`
        : JSON.stringify(v);
      console.log(`      ${k}: ${display}`);
    }
  }
}

// ─── Main ────────────────────────────────────────────────────────────────────

async function main(): Promise<void> {
  console.log("\n━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━");
  console.log(" South Lambeth Food & Wine — Firestore Seed Script");
  if (DRY_RUN) console.log(" MODE: DRY RUN — no data will be written");
  if (CLEAR_FIRST && !DRY_RUN) console.log(" MODE: CLEAR FIRST — existing docs will be deleted");
  console.log("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n");

  // Load seed data
  const seedPath = path.resolve(__dirname, "firestore_seed_data.json");
  const seedData = JSON.parse(
    fs.readFileSync(seedPath, "utf8")
  ) as Record<string, Record<string, unknown>[]>;

  // Seed each collection in dependency order (users & shops before dependent docs)
  const SEED_ORDER: Array<keyof typeof COLLECTION_CONFIG> = [
    "users",
    "shops",
    "pendingRequests",
    "employees",
    "items",
    "inventory",
    "purchaseRequests",
    "timesheets",
    "notifications",
  ];

  for (const collectionName of SEED_ORDER) {
    const config = COLLECTION_CONFIG[collectionName];
    const documents = seedData[collectionName] ?? [];
    process.stdout.write(`\n[${collectionName}]\n`);
    await seedCollection(collectionName, documents, config);
  }

  console.log("\n━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━");
  console.log(DRY_RUN ? " Dry run complete. No data was written." : " Seed complete.");
  console.log("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n");
}

main().catch((err) => {
  console.error("Seed script failed:", err);
  process.exit(1);
});
