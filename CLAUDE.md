# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

---

## Build & Run

Open the project in Xcode:
```
open "South Lambeth Food and Wine Store Inventory sys.xcodeproj"
```

Build and run via Xcode (⌘R). There is no CLI build script — use `xcodebuild` if needed:
```bash
xcodebuild -project "South Lambeth Food and Wine Store Inventory sys.xcodeproj" \
  -scheme "South Lambeth Food and Wine Store Inventory sys" \
  -destination "platform=iOS Simulator,name=iPhone 16" \
  build
```

Run tests:
```bash
xcodebuild test \
  -project "South Lambeth Food and Wine Store Inventory sys.xcodeproj" \
  -scheme "South Lambeth Food and Wine Store Inventory sys" \
  -destination "platform=iOS Simulator,name=iPhone 16"
```

---

## Project Goal

This is a **production-ready iOS inventory management system** for a food, wine, and off-licence retail store — not a demo or prototype. Every architectural decision must support:

- Offline + online data sync
- Scalable backend integration (Firebase, Cloud Functions, Cloudinary)
- Secure authentication flows (OTP, password reset, token validation)
- Media uploads (product images via Cloudinary)
- Extensibility for AI-powered features in future iterations

---

## Architecture: MVVM + MVI (Strict)

This project follows a **strict MVVM + MVI-style architecture**. Every screen is self-contained and follows the same contract. No exceptions.

### Core Principles

- The **ViewModel is the single source of truth** for all screen state
- The **UI must be dumb**: views only render state and emit events — never compute or decide
- **No business logic in Views**
- **Effects are strictly one-time actions**: navigation, alerts, toasts, opening URLs, triggering dialogs

### Layer Overview

```
App/           – Entry point (AppRootView, AppRoute), centralized navigation
Presentation/  – One folder per screen; each contains the full 5-file contract
Domain/        – Protocols, use-case interfaces, Firebase integration stubs
Shared/        – Reusable SwiftUI components (buttons, fields, top bars, cards)
UI/            – AppTheme: colors, typography, layout constants
```

### Screen Contract (5-file pattern)

Every screen must be structured into exactly these files:

| File | Role |
|---|---|
| `*UiState` | Plain `struct`, all display data. `@Published` on the VM. No logic. |
| `*UiEvent` | `enum` of every user interaction or intent sent into the VM via `onEvent(_:)` or `send(_:)`. |
| `*UiEffect` | `enum` of one-off side effects (navigation, toasts). Emitted via `AsyncStream` or `PassthroughSubject`. |
| `*ViewModel` | `@MainActor final class ObservableObject`. Owns state, processes events, emits effects. All async logic lives here. |
| `*RouteHostView` | Owns `@StateObject` VM. Connects effects stream to navigation closures injected from `AppRootView`. Passes `state` + `onEvent` down to Screen. |
| `*Screen` | Pure SwiftUI view. Receives `state` + `onEvent` closure — zero VM reference, zero business logic. |

Some screens (Gate, Home) consolidate State/Event/Effect into a single `*Contract.swift` — this is acceptable for simpler screens only.

### Code Generation Rules

When generating any new screen or feature, always produce **all five files** in full. Never skip or merge unless explicitly told to. Always include:

- `// MARK:` sections for readability
- A `#Preview` for light and dark mode
- `async/await` for all async operations
- Protocol-typed dependencies (never concrete types in host views)

---

## Navigation Architecture

Navigation is **fully centralised** in `AppRootView`.

### Flow

```
Gate (Splash)
  ├── authenticated  → Home
  └── unauthenticated → Welcome → Login ──────────────────────────────────────┐
                                    │                                          │
                                    ├── Sign Up → RoleSelection               │
                                    │               ├── Sign Up as User        │
                                    │               │     → SignUp (user form) │
                                    │               │       → OTP → Home       │
                                    │               └── Sign Up as Owner       │
                                    │                     → OwnerSignUp        │
                                    │                       → OwnerOTP → Home  │
                                    ├── ForgotPassword → SendResetMail        │
                                    │                     (email link)         │
                                    │                       → ResetPassword ───┘
                                    └── ← back ← RoleSelection / SignUp
```

### AppRoute cases

All cases defined in `App/AppRoute.swift`. `AppRoute: Hashable` — all associated value types must be `Hashable`.

| Case | Associated values | Notes |
|---|---|---|
| `.gate` | — | Splash / session check |
| `.welcome` | — | Landing screen |
| `.login` | — | |
| `.resetmail` | — | Send password reset email |
| `.resetPassword` | `token: String` | Arrived via deep link |
| `.roleSelection` | — | User vs Owner choice |
| `.signup` | — | Standard user sign-up form |
| `.otp` | `email`, `name`, `password` | User OTP verification |
| `.ownerSignUp` | — | Owner sign-up form |
| `.ownerOtp` | `email`, `name`, `password`, `shops: [OwnerShopEntry]`, `defaultShopId: UUID` | Owner OTP verification; carries full shop list in memory |
| `.home` | — | Main app |

### Rules

- `AppRoute` (enum in `App/AppRoute.swift`) is the only navigation source of truth
- `AppRootView` holds `@State var route: AppRoute` and `switch`es on it to render the active `RouteHostView`
- Navigation is **always triggered via Effects**: Screen emits event → VM emits effect → RouteHostView catches it → calls injected closure → AppRootView updates `route`
- There is **no `NavigationLink` or `NavigationStack` push/pop** — all transitions are root-level swaps animated with `.easeInOut(duration: 0.50)`
- Views must **never** control navigation directly

### Deep Link — Password Reset

The password reset email contains an HTTPS link to Firebase Hosting:
```
https://inventory-app-352dc.web.app/reset?token=<rawToken>
```

`public/reset.html` (Firebase Hosting) handles this URL. It immediately attempts a JS redirect to the custom scheme:
```
inventorysys://reset?token=<rawToken>
```
If the redirect doesn't fire within 2 seconds (e.g. opened in a browser), a fallback "Open App" button is shown.

`AppRootView` handles the custom scheme with `.onOpenURL`:
```swift
.onOpenURL { url in
    guard url.scheme == "inventorysys", url.host == "reset",
          let token = URLComponents(url: url, resolvingAgainstBaseURL: false)
              .queryItems?.first(where: { $0.name == "token" })?.value
    else { return }
    route = .resetPassword(token: token)
}
```

**Why HTTPS intermediary:** Raw `inventorysys://` links fail silently in Gmail, web browsers, and any context where the app is not installed. The Hosting page provides a graceful fallback and works in all email clients.

**Manual Xcode setup required** (one-time): Target → Info → URL Types → `+` → URL Schemes: `inventorysys`

**Firebase Hosting:** Configured in `firebase.json`. Source: `public/`. All routes rewrite to `reset.html`. Deploy with `firebase deploy --only hosting`.

---

## Session Persistence

The app remembers signed-in users across cold launches. No login screen is shown unless the user explicitly signed out.

### How it works

`Domain/Session/SessionChecking.swift` defines three types:

| Type | Role |
|---|---|
| `SessionChecking` | Read-only protocol — `isSignedIn() async -> Bool` |
| `SessionManaging` | Extends `SessionChecking` — adds `saveSession()` and `clearSession()` |
| `LocalSessionManager` | Concrete impl — stores `"app.isSignedIn"` boolean in `UserDefaults` |

`AppRootView` owns the `SessionManaging` instance and calls:
- `sessionManager.saveSession()` — on successful login (`onNavigateHome`), user OTP verification, and owner OTP verification
- `sessionManager.clearSession()` — when the user signs out from Home (`onNavigateWelcome`)

`GateViewModel` reads `sessionChecker.isSignedIn()` on launch and routes to `.home` or `.welcome` accordingly.

### Firebase swap path

Replace `LocalSessionManager` in `ContentView` with a `FirebaseSessionManager` that reads `Auth.auth().currentUser != nil`. No other file needs to change — `AppRootView` and `GateViewModel` are protocol-typed.

---

## Theming

All visual constants live in `UI/AppTheme.swift`. **Never hardcode colors, fonts, or spacing.**

| Namespace | Usage |
|---|---|
| `AppTheme.Colors` | All colors. Methods take `ColorScheme` for light/dark adaptation. |
| `AppTheme.Typography` | All `Font` values (title, body, button, caption, link, fieldValue, etc.) |
| `AppTheme.Layout` | All spacing, padding, corner radius, border width constants |

**Brand accent:** purple `#6B57A7` in light mode, yellow `#D6D000` in dark mode.

When adding new color or spacing values, always add them to `AppTheme` — never inline them in a View.

---

## Dependency Injection

Dependencies are injected as **protocol-typed values** into `RouteHostView` initialisers. Never reference concrete types (especially `Demo*` stubs) from anything other than previews and `AppRootView`.

Pattern:
```swift
// Protocol defined in Domain/
public protocol InventoryRepository { ... }

// Stub for development
public struct DemoInventoryRepository: InventoryRepository { ... }

// Injected at the host view level
InventoryRouteHostView(repository: DemoInventoryRepository()) { ... }
```

When Firebase is wired, swap `Demo*` for real implementations at `AppRootView` initialisation — no other file should need to change.

---

## Backend & Integration Architecture

### Core Services

| Service | Purpose |
|---|---|
| **Firebase Authentication** | User sign-in, sign-up, session management |
| **Cloud Firestore** | Cloud database for inventory, users, audit logs |
| **Google Cloud Functions** | Backend logic: OTP generation, token validation, password reset, registration |
| **Cloudinary** | Product image and file storage |

### Backend Responsibilities (never implement client-side)

- Email OTP generation and verification
- Password reset token creation and validation
- Token hashing, salting, and TTL enforcement
- User and owner registration (Auth user creation + Firestore writes)
- Any sensitive business logic that must not live in the client

### Firebase Status

| Flow | Protocol | Production impl | File | Status |
|---|---|---|---|---|
| Session check / save / clear | `SessionManaging` | `LocalSessionManager` | `Domain/Session/` | **Pending** — UserDefaults; swap for `FirebaseSessionManager` |
| Login | `LoginAuthenticating` | `FirebaseLoginAuthenticator` | `Domain/Firebase/` | Wired — `Auth.auth().signIn` |
| Register standard user | `UserRegistering` | `FirebaseUserRegistrar` | `Domain/Firebase/` | Wired — `registerUser` Cloud Function |
| Register owner | `OwnerRegistering` | `FirebaseOwnerRegistrar` | `Domain/Firebase/` | Wired — `registerOwner` Cloud Function |
| Send sign-up OTP | `SignUpOtpSending` | `FirebaseSignUpOtpSender` | `Presentation/SignUp/SignUpDependencies.swift` | Wired — `sendEmailOtp` Cloud Function |
| Verify OTP | `EmailOtpServicing` | `FirebaseEmailOtpService` | `Domain/Firebase/` | Wired — `verifyEmailOtp` Cloud Function |
| Send password reset email | `PasswordResetSending` | `FirebasePasswordResetSender` | `Domain/Firebase/` | Wired — `requestPasswordResetLink` Cloud Function |
| Reset password with token | `PasswordResetting` | `FirebasePasswordResetter` | `Domain/Firebase/` | Wired — `resetPasswordWithToken` Cloud Function |
| Manage shop (load/add/edit/remove/switch) | `ShopManaging` | `FirebaseShopManager` | `Domain/Firebase/FirebaseShopManager.swift` | Wired — direct Firestore reads/batch writes |
| Fetch owners for sign-up picker | `OwnerFetching` | `FirebaseOwnerFetcher` | `Presentation/SignUp/SignUpDependencies.swift` | Wired — Firestore query by `role == "owner"` |

`Demo*` stubs exist for every protocol — previews and unit tests only. Never use them in `AppRootView`.

**Remaining Firebase swap:** Replace `LocalSessionManager` in `ContentView.swift` with a `FirebaseSessionManager` that reads `Auth.auth().currentUser != nil`. No other file needs to change.

### Deployed Cloud Functions (`functions/src/index.ts`, region: `europe-north1`)

| Function | Purpose |
|---|---|
| `sendEmailOtp` | Generates 4-digit OTP, hashes+salts, stores in `email_otp` Firestore collection, sends via AWS SES |
| `verifyEmailOtp` | Re-hashes entered OTP with stored salt, timing-safe compare, deletes record on success |
| `registerUser` | Creates Firebase Auth user + writes `users` Firestore document (`role: "standard"`, `shopIDs: []`) |
| `registerOwner` | Creates Firebase Auth user + batch-writes `users` doc (`role: "owner"`), all `shops` docs, and one `employees` doc per shop; rolls back Auth user if batch fails |
| `requestPasswordResetLink` | Generates secure token, hashes+salts, stores in `password_reset_tokens`, sends deep link email |
| `resetPasswordWithToken` | Validates token, updates Firebase Auth password, invalidates token |
| `sendTestEmail` | Retained in backend — not called from iOS app |

AWS SES is **out of sandbox** — all functions send to any email address.

### `OwnerRegistering` protocol (`Domain/Firebase/FirebaseOwnerRegistrar.swift`)

```swift
public protocol OwnerRegistering {
    func registerOwner(
        name: String, email: String, password: String,
        shops: [OwnerShopPayload], defaultShopId: String
    ) async throws
}
```

`OwnerShopPayload` is a plain value type defined in the same file that maps `OwnerShopEntry` fields to the dict format expected by the `registerOwner` Cloud Function. It is separate from `OwnerShopEntry` so the Domain layer has no import dependency on Presentation.

The `registerOwner` Cloud Function:
- Validates all fields + password strength + each shop has `shopId`, `name`, `address`
- Verifies `defaultShopId` is in the shops list
- Checks for duplicate email in Firebase Auth
- Creates Firebase Auth user
- Writes a single Firestore batch: `users/{uid}`, `shops/{shopId}` × N, `employees/{uid}_{shopId}` × N
- Employee ID is deterministic (`{uid}_{shopId}`) — safe to retry without creating duplicates
- If batch fails, Auth user is deleted immediately (no orphan accounts)

---

## Firestore Schema

The canonical schema is defined in `firestore/firestore_schema_spec.json`. **Always consult this file before adding or modifying Firestore documents.** Do not rename fields without updating both the schema spec and the Cloud Function that writes to that collection.

### Collections

| Collection | Document ID field | Key fields |
|---|---|---|
| `users` | `userID` | `name`, `email`, `role` (`owner`/`supervisor`/`admin`/`standard`), `shopIDs: [string]`, `currentShopID: string?`, `createdAt`, `updatedAt` |
| `shops` | `shopID` | `name`, `address`, `ownerUserID`, `phone`, `isDefault: bool`, `latitude`, `longitude`, `createdAt`, `updatedAt` |
| `pendingRequests` | `requestID` | `name`, `email`, `shopID`, `status` (`pending`/`approved`/`rejected`), `requestedAt`, `approvedBy?`, `approvedAt?` |
| `employees` | `employeeID` | `userID`, `shopID`, `role`, `createdAt`, `updatedAt` |
| `items` | `itemID` | `name`, `category`, `subcategory`, `size`, `packSize`, `barcode`, `brand`, `supplier?`, `lowStockThreshold`, `inStockThreshold` |
| `inventory` | `inventoryID` | `itemID`, `shopID`, `quantityOnHand`, `updatedBy`, `updatedAt` |
| `purchaseRequests` | `requestID` | `shopID`, `items: [{itemID, quantity}]`, `requestedBy`, `requestedAt`, `status`, `approvedBy?`, `approvedAt?` |
| `timesheets` | `timesheetID` | `userID`, `shopID`, `date` (string), `checkIn` (string), `checkOut` (string), `createdAt` |
| `notifications` | `notificationID` | `userID`, `shopID`, `title`, `message`, `type`, `referenceID`, `metadata`, `isRead`, `createdAt`, `readAt?`, `createdBy` |

Internal-only collections (not in schema spec, used by Cloud Functions):

| Collection | Purpose |
|---|---|
| `email_otp` | Temporary OTP records — TTL-enforced, deleted on successful verify |
| `password_reset_tokens` | Temporary reset tokens — TTL-enforced, deleted on use |
| `password_reset_rate` | Per-email rate-limiting for reset requests |

### Seed Script (`firestore/`)

`firestore/seed.ts` is a standalone TypeScript script (separate from deployed functions) that seeds all 9 collections from `firestore/firestore_seed_data.json`.

```bash
cd firestore
npm install
export GOOGLE_APPLICATION_CREDENTIALS=/path/to/serviceAccount.json
npm run seed:dry    # preview — no writes
npm run seed        # write all collections
npm run seed:clear  # delete existing docs first, then seed
```

- Uses `documentId` from the schema spec for all document IDs
- Converts ISO date strings → Firestore `Timestamp`; preserves `null` on nullable timestamp fields
- Writes in dependency order: `users → shops → pendingRequests → employees → items → inventory → purchaseRequests → timesheets → notifications`
- Batched in 500-op chunks (Firestore limit)

---

## Data Layer Architecture

Structure all data access behind clean abstractions, ready for real implementations.

### Planned Repository Interfaces (Domain layer)

```swift
protocol SessionRepository     // Auth state, token refresh
protocol AuthRepository        // Sign in, sign up, password reset
protocol InventoryRepository   // CRUD for inventory items
protocol ProductRepository     // Product lookup, barcode resolution
```

Each repository must:
- Abstract both remote and local data sources
- Support offline-first operation with sync
- Be injected as a protocol type — never instantiated directly in a VM

### Remote Layer
- Firebase SDK calls wrapped behind repository implementations
- Cloud Functions called via `URLSession` or Firebase Callable Functions SDK
- Barcode / product API client (URLSession-based, Moya/Alamofire style)

### Local Layer
- **SwiftData** (preferred) or Core Data for inventory persistence
- Caching layer for product lookup results
- Offline queue for mutations pending sync

### Secure Storage
- **Keychain**: session tokens, credentials, sensitive user data
- **UserDefaults**: non-sensitive UI preferences only

---

## OTP & Security Design

### OTP Cooldown (EmailOtpVerificationViewModel)

Escalating resend cooldown: `60s → 2m → 5m → 30m → 1h`

- Defined in `cooldownPresets: [Int]`
- Cooldown starts immediately on VM init (OTP sent from SignUp before navigation)
- 4-digit OTP input supports paste-spread across individual boxes
- OTP TTL sent to backend: **300 seconds** (5 minutes) — set in `FirebaseSignUpOtpSender` and `FirebaseEmailOtpService.resendOtp`

The same `EmailOtpVerificationRouteHostView` is used for both user signup (`.otp` route) and owner signup (`.ownerOtp` route). The `onVerified` closure differs: user OTP calls `registrar.register()`; owner OTP calls `ownerRegistrar.registerOwner()` with the full shop payload.

### OTP Input — Focus & Autofill Rules (`EmailOtpVerificationScreen`)

**Critical — do not regress these patterns:**

- `.textContentType(.oneTimeCode)` is applied **only to box 0**. Applying it to all 4 boxes causes iOS autofill to freeze the keyboard when surfacing the "From Messages" suggestion.
- Focus advancement is driven by `.onChange(of: state.otpDigits[index])` on each box, **not** inside the `Binding` setter. Modifying `@FocusState` inside a `Binding` setter runs during SwiftUI's view-update cycle and causes re-entrant updates / UI freezes.
- All `state` mutations in `applyOtpInput` and `recalcDerived` are batched: copy `state` into a local `var`, mutate the copy, assign back once — a single `objectWillChange` publish per event.
- Paste-spread logic (`digitsOnly.count > 1`) lives in `EmailOtpVerificationViewModel.applyOtpInput`; focus jumps after paste are handled in the `.onChange` modifier via `fieldAfterPastedDigits(from:count:)`.

### Password Reset Flow

Full end-to-end flow across `SendResetMail` → email → deep link → `ResetPassword`:

1. User enters email on `SendResetMailScreen` → VM calls `FirebasePasswordResetSender.sendResetLink`
2. Backend (`requestPasswordResetLink`) generates token, hashes it, stores hash, sends email — **always returns neutral response** regardless of whether the email exists (prevents account enumeration)
3. Email contains HTTPS link: `https://inventory-app-352dc.web.app/reset?token=<rawToken>`
4. Tapping the link opens `public/reset.html` (Firebase Hosting) → JS redirects to `inventorysys://reset?token=<rawToken>` → `AppRootView.onOpenURL` parses the token → `route = .resetPassword(token:)`
5. User enters new password on `ResetPasswordScreen` → VM calls `FirebasePasswordResetter.resetPassword`
6. Backend (`resetPasswordWithToken`) validates token (existence, expiry, used flag), updates Firebase Auth password, deletes token
7. On success: toast + navigate to Login. On failure: inline error with reason (`expired` / `used` / `invalid`)

Password strength rules are enforced both client-side (`ResetPasswordViewModel.isStrongPassword`) and server-side (`isStrongPassword` in Cloud Functions) — **both must stay in sync**.

### Security Rules (client-side)

- Never perform OTP or token validation on-device — always call the Cloud Function
- Never store raw tokens in UserDefaults — always use Keychain
- Never expose Firebase project secrets in source code
- Firestore rules must enforce TTL on temporary secure documents (`email_otp`, `password_reset_tokens` collections)
- `SendResetMailViewModel` swallows backend errors intentionally — neutral UX prevents email enumeration attacks

---

## UI Components (Shared)

All reusable UI lives in `Shared/`. When building new screens, use existing components before creating new ones.

| Component | File | Notes |
|---|---|---|
| `AppPillButton` | `Shared/AppPillButton.swift` | Primary CTA button, supports loading + disabled state |
| `OutlinedTextField` | `Shared/OutlinedTextField.swift` | Labelled input with border, keyboard type, content type |
| `OutlinedPasswordField` | `Shared/OutlinePasswordField.swift` | Password input with visibility toggle |
| `AppTopBar` | `Shared/AppTopBar.swift` | Title bar with optional back button and shadow — auth screens only |
| `AppScreenHeader` | `Shared/AppScreenHeader.swift` | Main tab header: profile pic + accent title + bell + drawer button |
| `AppSearchFilterBar` | `Shared/AppSearchFilterBar.swift` | Search pill + filter button — used on all four main tabs |
| `AppBottomNavBar` | `Shared/AppBottomNavBar.swift` | Frosted glass tab bar with elevated scan FAB |
| `AppDrawer` | `Shared/AppDrawer.swift` | Left slide-in navigation drawer with profile, menu items, and logout |
| `AppLoadingOverlay` | `Shared/AppLoadingOverlay.swift` | Full-screen blocking overlay with spinner — shown during async pre-navigation operations |

### AppScreenHeader

Design ref: `/Users/mariyananjelo/Documents/Nishan Off Licence/App Design/Components/head.png`

Layout: `[ProfilePic] ── [Title (accent)] ── [Bell + badge] [Drawer ≡]`

- Profile image: `Image("ProfilePic")` — asset `Assets.xcassets/ProfilePic.imageset/` (source: `AppResources/Profile Pic.JPG`)
- Title colour: `AppTheme.Colors.accent(scheme)`
- Bell badge: shown when `hasUnreadNotification == true`
- Drawer button (`line.3.horizontal`): calls `onDrawerTapped` closure — defaults to `{}` so previews need no changes
- Both bell and drawer button use `surfaceContainer` circle background

### AppDrawer

Left-side navigation drawer. Used exclusively from `HomeScreen` via `@State private var isDrawerOpen`.

**Structure:**
- Top: profile pic, "Store Manager" name, "South Lambeth Store" subtitle, close `×` button
- Middle: scrollable menu rows in two groups separated by a `Divider`:
  - Group 1 (nav): Profile, **Manage Shop**, Report, TimeSheet, History, Terms & Conditions
  - Group 2 (print): Set Print Order, Print
- Bottom: Logout row pinned below a `Divider`, styled in `AppTheme.Colors.error(scheme)`

**Callbacks:**
| Parameter | Wired to |
|---|---|
| `onLogout` | `HomeEvent.onSignOutTapped` |
| `onSetPrintOrderTapped` | `HomeEvent.openSetPrintOrder` |
| `onManageShopTapped` | `HomeEvent.openManageShop` |

**Behaviour:**
- Spring animation (`response: 0.32, dampingFraction: 0.88`) on open/close
- Semi-transparent black backdrop (`opacity: 0.45`) — tap to dismiss
- All items close the drawer first, then fire their action after 250 ms so the animation completes
- `onLogout` wires to `onEvent(.onSignOutTapped)` in `HomeScreen`, which flows through `HomeViewModel → HomeRouteHostView → AppRootView → sessionManager.clearSession()`

**Wiring pattern — do not break this chain:**
```
AppDrawer.onLogout
  → HomeScreen: onEvent(.onSignOutTapped)
  → HomeViewModel: emit(.navigateWelcome)
  → HomeRouteHostView: onNavigateWelcome()
  → AppRootView: sessionManager.clearSession(); route = .welcome
```

**Drawer trigger propagation:**
`HomeScreen` owns `@State private var isDrawerOpen`. It passes `onDrawerTapped: { isDrawerOpen = true }` directly to each tab screen's init. Each tab screen forwards it to `AppScreenHeader`. Never wire drawer state through the ViewModel or UiEvent system — it is a pure UI concern.

### PrintSheetView (private, inside AppDrawer.swift)

Presented as a `.sheet` from `AppDrawer` when the user taps Print.

- Print preview: store header (name, report type, timestamp) + striped table (Item | SKU | Stock)
- Low-stock rows highlighted in `AppTheme.Colors.error(scheme)`
- **Cancel** — dismisses the sheet; styled with `surfaceContainer` fill
- **Print** — fires iOS native `UIPrintInteractionController` with inventory data formatted as plain text; styled with `accent` fill
- Sample data is hardcoded — replace with real `InventoryRepository` data once the data layer is wired (`// MARK: Firebase – pending` comment in file)

### SetPrintOrderSheetView (private, inside AppDrawer.swift)

Presented as a `.sheet` from `AppDrawer` when the user taps Set Print Order.

- Currently a placeholder screen ("Coming soon" pill) marked `// MARK: Firebase – pending`
- When inventory data layer is wired, implement drag-to-reorder using SwiftUI `List` with `.onMove` to let users control item order in printed reports

### AppSearchFilterBar

Design ref: `/Users/mariyananjelo/Documents/Nishan Off Licence/App Design/Components/Search_and_filter.png`

Theming rule — **always use surface elevation, never inverted colors**:
- Fill: `AppTheme.Colors.surfaceContainer(scheme)` — one level above background in both themes
- Text: `AppTheme.Colors.primaryText(scheme)` / placeholder: `AppTheme.Colors.secondaryText(scheme)`
- Each screen owns a local `@State private var searchText = ""` and passes it as a `Binding`

### AppBottomNavBar

- Background: `.ultraThinMaterial` (frosted glass blur) + `fieldBorderVariant` stroke
- Active tab: `AppTheme.Colors.accent(scheme)`
- Inactive tab: `AppTheme.Colors.secondaryText(scheme)`
- Scan FAB: `accent` fill, `buttonText` icon

### AppLoadingOverlay

Full-screen blocking overlay displayed in `AppRootView` during any async operation that precedes a navigation transition (login, OTP verify, password reset, registration).

**Behaviour:**
- Semi-transparent black scrim (`opacity: 0.45`) + accent-coloured `ProgressView` spinner (scale 1.4×)
- `allowsHitTesting(true)` — blocks all user interaction while visible
- Fades in/out via `.animation(.easeInOut(duration: 0.2), value: isBlocking)`

**Wiring pattern:**
```
ViewModel.state.isLoading / isVerifying / isSubmitting  (already exists per screen)
  ↓ .onChange in RouteHostView
  ↓ onLoadingChanged(Bool) callback
AppRootView.isBlocking (@State)
  ↓
AppLoadingOverlay (overlaid above all content)
```

Each affected RouteHostView accepts `onLoadingChanged: @escaping (Bool) -> Void = { _ in }` and forwards the ViewModel's loading flag via `.onChange`. `AppRootView` sets `isBlocking` from this callback.

**Affected RouteHostViews and their loading state property:**
| RouteHostView | VM loading property |
|---|---|
| `LoginRouteHostView` | `state.isLoading` |
| `SignUpRouteHostView` | `state.isLoading` |
| `OwnerSignUpRouteHostView` | `state.isLoading` |
| `EmailOtpVerificationRouteHostView` | `state.isVerifying` |
| `SendResetMailRouteHostView` | `state.isSubmitting` |
| `ResetPasswordRouteHostView` | `state.isLoading` |

The inline OTP registration `Task` in `AppRootView` (`.otp` and `.ownerOtp` cases) sets `isBlocking` directly before/after the registration call.

### Theming Rule for All New Components

**Never use inverted or hardcoded hex fills for surfaces.** Use `AppTheme.Colors.surfaceContainer(scheme)` for fields, bars, and cards. Use `.ultraThinMaterial` for floating/overlaid surfaces (bottom bars, sheets). Only accent-coloured CTAs may use `AppTheme.Colors.accent(scheme)` as a fill.

### Design Sample Files

Reference images for new components:
- Components: `/Users/mariyananjelo/Documents/Nishan Off Licence/App Design/Components/`
- Assets (logos, profile pic): `/Users/mariyananjelo/Documents/Nishan Off Licence/App Design/AppResources/`

Always read the relevant design image before building a new component.

When adding new shared components:
- Accept state via plain value parameters (not bindings where avoidable)
- Emit actions via closures
- Use `AppTheme` exclusively for styling
- Always include a `#Preview` for light and dark mode

### Scanner Screen — Safe Area

`ScannerScreen` uses `.ignoresSafeArea()` on its root `ZStack` so the camera fills the full screen. The top bar (close, title, torch) reads the device's actual safe area inset at runtime:

```swift
.padding(.top: (UIApplication.shared.connectedScenes
    .compactMap { $0 as? UIWindowScene }
    .first?.windows.first?.safeAreaInsets.top ?? 0) + 12)
```

Never use a hardcoded top padding on the scanner — insets differ across devices (Dynamic Island, notch, flat top).

### Home Screen — Current State & Upcoming

`HomeState` contains only `selectedTab: AppNavTab`. The sign-out button has been removed from the dashboard; logout is now exclusively in `AppDrawer`.

`HomeScreen.tabContent` switches on `state.selectedTab` and renders:
- `.home` → `HomeDashboardView` (placeholder with store name/icon)
- `.inventory` → `InventoryRouteHostView` (fully wired MVI screen)
- `.report` → `ReportScreen`
- `.categories` → `CategoriesScreen`

Each tab receives `onDrawerTapped: { isDrawerOpen = true }` from `HomeScreen`.

Upcoming dashboard (`.home` tab) content:
- Inventory statistics (total items, total value, low stock count)
- Stock overview by category
- Filters (category, low stock, expiry, etc.)
- Recent stock updates / audit log
- Product quick actions (scan barcode, add item, export PDF)

### Role Selection Screen

Intermediate screen inserted between Login → SignUp. Files: `Presentation/RoleSelection/` (full 5-file contract).

- Two role cards: **Sign Up as User** (`person.fill`) and **Sign Up as Owner** (`building.2.fill`)
- Back navigates to `.login`; user card → `.signup`; owner card → `.ownerSignUp`
- No state beyond static labels — `RoleSelectionViewModel` is a pure effect emitter

### Owner Sign Up Screen

Full onboarding screen for store owners — OTP flow and backend registration fully wired. Files: `Presentation/OwnerSignUp/` (full 5-file contract).

**Features:**
- Account details section: Name, Email, Password, Retype Password (same password strength rules as user signup)
- **Shop list section** — owner must add at least one shop before submitting
- Each shop entry: Name, Address, Phone (UK-style mask `XXXXX XXXXXX`), Location (tappable stub — `// MARK: Firebase – pending` for Google Maps picker storing `latitude`/`longitude`)
- **Add/Edit shop** via `ShopFormSheet` (private sheet in `OwnerSignUpScreen.swift`) — name and address are required; phone and location are optional
- **Delete shop** requires typing `CONFIRM` exactly in `DeleteConfirmSheet` before the Remove button activates; button animates from disabled (grey) → enabled (red)
- **Default shop picker** — appears below the shop list once at least one shop is added; radio-button style rows; first shop is auto-selected; re-assigns automatically when the default shop is deleted

**Key models (defined in `OwnerSignUpUiState.swift`):**

| Type | Role |
|---|---|
| `OwnerShopEntry` | `id: UUID`, `name`, `address`, `phone` (masked), `locationLabel`, `latitude?`, `longitude?`. Conforms to `Identifiable, Equatable, Hashable` (Hashable required by `AppRoute.ownerOtp`). |
| `OwnerSignUpUiState` | Account fields, `shops: [OwnerShopEntry]`, `defaultShopId: UUID?`, sheet presentation flags, `draftShop`, `deleteConfirmText`, `isLoading` |

**`OwnerSignUpUiEffect` cases:**
| Effect | When emitted |
|---|---|
| `.navigateBack` | Back button tapped |
| `.showToast(String)` | Validation error or OTP send failure |
| `.navigateToOtp(email:name:password:shops:defaultShopId:)` | OTP sent successfully — carries full shop list in memory for `registerOwner` call after verification |

**`OwnerSignUpViewModel` dependencies:**
- `otpSender: SignUpOtpSending` — injected via `OwnerSignUpRouteHostView`; defaults to `DemoSignUpOtpSender` for previews

**Submit flow:**
1. Validates all fields + password strength + shops not empty + default shop selected
2. `state.isLoading = true`
3. Calls `otpSender.sendOtp(to: email)`
4. On success: `isLoading = false`, emits `.navigateToOtp(...)`
5. On failure: `isLoading = false`, emits `.showToast("Failed to send verification code. Please try again.")`

**Pending (`// MARK: Firebase – pending`):**
- `draftShopLocationTapped` shows "Location picker coming soon" toast — replace with Google Maps SDK sheet that writes `locationLabel`, `latitude`, `longitude`
- Back navigation from `.ownerOtp` goes to `.ownerSignUp` (form resets); future improvement: preserve form state

### User Sign Up — Store Assignment

`SignUpScreen` now includes a **Store Assignment** card section (below password rules, above the Sign Up button). The user must select an owner and a default shop before the form can be submitted.

**Models (defined in `SignUpUiState.swift`):**

| Type | Role |
|---|---|
| `SignUpOwner` | `id: String`, `name`, `storeName`, `shops: [SignUpShop]` |
| `SignUpShop` | `id: String`, `name`, `address` |

**Note:** Both `id` fields are `String` (Firestore document IDs are strings, not `UUID`). `storeName` is derived from `shops.first?.name` in `FirebaseOwnerFetcher` since there is no `storeName` field on the `users` document.

**State additions to `SignUpUiState`:**
- `availableOwners: [SignUpOwner]` — populated live via `FirebaseOwnerFetcher.fetchOwners()` on `.onAppear`; defaults to `[]`
- `isLoadingOwners: Bool` — true while `fetchOwners()` is in flight; disables + shows spinner in the owner picker row
- `selectedOwner: SignUpOwner?`, `selectedShop: SignUpShop?`
- `isOwnerPickerPresented: Bool`, `isShopPickerPresented: Bool`

**`OwnerFetching` protocol (`Presentation/SignUp/SignUpDependencies.swift`):**
```swift
public protocol OwnerFetching {
    func fetchOwners() async throws -> [SignUpOwner]
}
```
- `FirebaseOwnerFetcher`: queries `users` where `role == "owner"`, then for each owner queries `shops` where `ownerUserID == uid`; derives `storeName` from first shop name
- `DemoOwnerFetcher`: returns `SignUpUiState.mockOwners` after 600 ms (previews only)
- `SignUpRouteHostView` accepts `ownerFetcher: OwnerFetching = DemoOwnerFetcher()` — `AppRootView` passes `FirebaseOwnerFetcher()`
- `SignUpViewModel` calls `Task { await loadOwners() }` on `.onAppear`

**Validation rules (enforced in `SignUpViewModel.signUp()`):**
1. Owner must be selected
2. Selected owner must have at least one shop
3. Default shop must be selected
4. All existing password/field rules still apply

**`OwnerPickerSheet`** (private, inside `SignUpScreen.swift`):
- Searchable — filters by owner name or store name (case-insensitive)
- Only shows owners with `shops.count > 0` (`eligibleOwners` computed property)
- Two empty states: no search results vs no eligible owners at all
- Selected owner shows accent circle + checkmark; `×` clear button resets both owner and shop selection

**`ShopPickerSheet`** (private, inside `SignUpScreen.swift`):
- Displays shops belonging to the selected owner only
- Disabled and shows "Select an owner first" until an owner is selected

**Post-OTP flow (`// MARK: Firebase – pending`):**
- After OTP verification, a join-request must be submitted to the selected owner (`selectedOwner.id`, `selectedShop.id`) for approval before the account becomes active
- The current `registrar.register()` call in `AppRootView` is a placeholder — replace with a join-request Cloud Function that writes to `pendingRequests` and sends a notification to the owner

**Social sign-in buttons (Google / Apple):**
Commented out in `SignUpScreen.swift` — not removed, ready to re-enable once OAuth is wired.

### Manage Shop Screen

Full-screen shop management screen accessible from the drawer via "Manage Shop". Behaviour differs by role: owners can add, edit, and remove shops; standard users switch between assigned shops. Files: `Presentation/SwitchShop/` (full 5-file contract — filenames use `SwitchShop` prefix).

**`SwitchShopEntry`** (defined in `SwitchShopUiState.swift`):
- `id: String` — Firestore document ID (UUID string for shops, Auth UID for users); **not** `UUID` type
- `name: String`, `address: String`, `phone: String`, `isCurrentShop: Bool`
- `isDefaultShop: Bool` — mirrors Firestore `shops/{id}.isDefault`; true when the owner has globally designated this as the active shop for all users

**`SwitchShopUiState`:**
- `shops: [SwitchShopEntry]` — loaded from Firestore via `ShopManaging`
- `isOwner: Bool` — set from `users/{uid}.role` on load; controls which owner-only UI elements are shown
- `isLoadingShops: Bool` — true while `loadShops()` is in flight; screen shows centred `ProgressView`
- `isSwitching: Bool` — true during a shop switch
- `isDeletingShop: Bool` — true during a delete call
- `isSettingDefault: Bool` — true while the Firestore batch to change the global default is in flight
- `isShopFormPresented: Bool` — controls add/edit sheet
- `editingShopId: String?` — nil = add mode, non-nil = edit mode
- `draftName`, `draftAddress`, `draftPhone: String` — form field state
- `deletingShopId: String?` — non-nil when delete sheet is open
- `deleteConfirmText: String` — must equal `"CONFIRM"` to enable delete button
- `pendingSwitchShopId: String?` — non-nil when user taps the toggle (triggers confirm alert)
- Computed: `currentShop`, `otherShops`, `isFormValid`, `isDeleteConfirmValid`, `shopBeingDeleted`, `pendingSwitchShop`
- `mockShops` static property — 3 shops with string IDs; first shop has `isCurrentShop: true, isDefaultShop: true`

**`SwitchShopUiEffect`:** `close`, `showToast(String)`

**`SwitchShopUiEvent`:**
- `.onAppear` — triggers Firestore load
- `.closeTapped` — emits `.close` effect
- `.shopTapped(id: String)` — user only: sets `pendingSwitchShopId` (triggers confirm alert)
- `.switchConfirmed` / `.switchCancelled` — user confirm alert result
- `.setDefaultShopTapped(id: String)` — owner only: sets global default + current shop for all users
- `.addShopTapped`, `.editShopTapped(id: String)` — owner: opens `ShopFormSheet`
- `.draftNameChanged`, `.draftAddressChanged`, `.draftPhoneChanged` — live form field updates
- `.saveShopTapped` — owner: calls `shopManager.addShop()` or `shopManager.updateShop()`
- `.shopFormDismissed` — clears draft state
- `.deleteShopTapped(id: String)` — owner: opens `DeleteConfirmSheet`; guards `shops.count > 1`
- `.deleteConfirmTextChanged`, `.confirmDeleteTapped`, `.deleteSheetDismissed`

**`ShopManaging` protocol (`Domain/Firebase/FirebaseShopManager.swift`):**
```swift
public protocol ShopManaging {
    func loadShops() async throws -> (entries: [SwitchShopEntry], isOwner: Bool)
    func addShop(name: String, address: String, phone: String) async throws -> SwitchShopEntry
    func updateShop(id: String, name: String, address: String, phone: String) async throws
    func removeShop(id: String) async throws
    func setDefaultShop(id: String) async throws   // owner: Firestore batch — isDefault flag on all shops
    func setCurrentShop(id: String) async throws   // all users: writes users/{uid}.currentShopID + UserDefaults
    func setActiveShop(id: String)                 // synchronous UserDefaults cache only
    func activeShopId() -> String?                 // reads UserDefaults "app.activeShopId"
}
```
- `FirebaseShopManager` (production): reads `users/{uid}.role` to determine owner vs user; owners query `shops where ownerUserID == uid`; users fetch `users/{uid}.shopIDs[]` then load each shop by ID
- `loadShops()` active-shop priority: 1) `users/{uid}.currentShopID` from Firestore, 2) UserDefaults `"app.activeShopId"` cache, 3) shop with `isDefault: true`, 4) first shop
- `addShop()`: batch — `shops/{newId}` (with `isDefault: false`) + `arrayUnion` on `users/{uid}.shopIDs` + `employees/{uid}_{newId}` with `role: "owner"`
- `removeShop()`: batch — delete `shops/{id}` + `arrayRemove` from `users/{uid}.shopIDs` + delete `employees/{uid}_{id}`; if removed shop was active, also deletes `users/{uid}.currentShopID` field in the same batch
- `updateShop()`: updates `name`, `address`, `phone`, `updatedAt` on `shops/{id}`
- `setDefaultShop(id:)`: queries all owner's shops, batch-sets `isDefault: true` on target and `isDefault: false` on all others
- `setCurrentShop(id:)`: writes `users/{uid}.currentShopID = id` to Firestore + updates UserDefaults cache
- `DemoShopManager(ownerMode: Bool)`: returns `mockShops` after delays for previews

**Screen layout:**
- Loading: centred `ProgressView` replaces list when `isLoadingShops == true`
- Owner view: flat "Your Shops" list; each row has `[ON/OFF toggle] [pencil] [trash]` action buttons; no tap on row body
- User view: flat "Your Shops" list; each row has an `[ON/OFF toggle]` — tapping an OFF toggle triggers the confirm alert
- Active row styling: accent border + accent background tint; storefront icon fills when active
- Green `checkmark.circle.fill` appears inline after the shop name when the toggle is ON
- Toggle visual: iOS-style pill switch — accent fill + white thumb with ✓ checkmark when ON; grey when OFF
- Owner toggle: calls `setDefaultShopTapped` → Firestore `isDefault` batch + `setCurrentShop`
- User toggle: calls `shopTapped` → `.alert` confirm dialog → `setCurrentShop`
- "Updating default…" spinner overlay while `isSettingDefault == true`
- Add/Edit sheet (`ShopFormSheet`): Name (required), Address (required), Phone (optional); Save enabled when `isFormValid`
- Delete sheet (`DeleteConfirmSheet`): trash icon header, `OutlinedTextField` "Type CONFIRM", Remove button animates disabled (grey) → enabled (red) when `deleteConfirmText == "CONFIRM"`
- Toast banner after switch/add/edit/delete

**Active shop persistence:**
- **Primary**: `users/{uid}.currentShopID` (String) in Firestore — cross-device, used as the item-list scope key when the inventory screen is wired
- **Cache**: `UserDefaults "app.activeShopId"` — offline fallback; kept in sync by `setCurrentShop(id:)` and `setActiveShop(id:)`
- `removeShop()` atomically deletes `currentShopID` from the user doc if the removed shop was active; auto-promotes the first remaining shop via `setCurrentShop`
- **Future**: scope all `inventory` and `items` Firestore queries by `currentShopID` so each shop's stock is independent

**Wiring (Home chain):**
```
AppDrawer.onManageShopTapped
  → HomeScreen: onEvent(.openManageShop)
  → HomeViewModel: emit(.openManageShop)
  → HomeRouteHostView: showManageShop = true → fullScreenCover(SwitchShopRouteHostView(shopManager: FirebaseShopManager()))
```

**`AppTopBar` — `trailingContent` slot:**
`AppTopBar` accepts an optional `trailingContent: AnyView?` (default `nil`). When non-nil it renders in the trailing position; otherwise renders a same-size `Color.clear` placeholder to keep the title centred. Used by `SwitchShopScreen` to inject the "Add Shop" button for owners. All existing callers are unaffected.

### Inventory Screen

Fully implemented on the MVI 5-file contract. Files: `InventoryUiState.swift`, `InventoryUiEvent.swift`, `InventoryUiEffect.swift`, `InventoryViewModel.swift`, `InventoryRouteHostView.swift`, `InventoryScreen.swift`.

**Key models (defined in `InventoryUiState.swift`):**

| Type | Role |
|---|---|
| `InventoryItem` | `id`, `name`, `category`, `sku`, `stock`, `icon`; computed `isLowStock` (`stock > 0 && stock < 10`), `isOutOfStock` (`stock == 0`) |
| `InventoryFilter` | `.totalItems` / `.lowStock` / `.outOfStock` — single-select |
| `InventoryUiState` | Week context (`selectedWeek/Month/Year`), `inventoryExistsForSelectedWeek`, `activeFilter`, `searchText`, `allItems`; derived `filteredItems`, stat counts, `weekHeaderLabel` |

**Features:**
- Week-context header bar with "Change" button → `InventoryWeekPickerSheet`
- Dynamic primary CTA: "Create New Inventory" (week has no data) or "Edit Inventory" (week has data); controlled by `inventoryExistsForSelectedWeek`
- Three compact filter stat cards (Total Items / Low Stock / Out of Stock) — tap to filter the list
- Item list with out-of-stock / low-stock indicators; empty state when filter returns no results
- Search via `AppSearchFilterBar` (binding bridge in screen, event via `.searchChanged`)

**`InventoryWeekPickerSheet`** (private, inside `InventoryScreen.swift`):
- Calendar-style week picker; each row = one ISO week
- Month/year navigation arrows + compact year wheel (`2020–2035`)
- Tapping a row fires `onWeekSelected`, `onMonthSelected`, `onYearSelected` events
- Presented as `.sheet(isPresented:)` — `@State private var isPickerPresented` lives in `InventoryScreen` (pure UI concern, not in VM)

**Mock data:**
- `InventoryUiState.mockItems` — 10 items covering Wine, Beer, Spirits, Soft Drinks, Snacks
- `InventoryUiState.weeksWithInventory: Set<Int> = [13, 14, 15]` — demo weeks that simulate existing inventory; replace with Firestore query once data layer is wired

**Pending (`// MARK: Firebase – pending`):**
- `InventoryUiEffect` is currently empty; future effects: `navigateToCreateInventory(weekId:)` and `navigateToEditInventory(weekId:)` once the inventory data layer is wired
- `onTapCreateOrEditInventory` in VM is a `break` stub — wire to effect emission once routes exist
- Replace mock items and `weeksWithInventory` with `InventoryRepository` Firestore calls against the `inventory` and `items` collections

---

## API Integration (Retail)

The app will integrate external product APIs. Structure all calls behind `ProductRepository` so the data source can be swapped without touching ViewModels.

Planned integrations:
- Barcode lookup APIs (UK retail datasets)
- Product metadata and image retrieval
- Open Food Facts or similar open dataset as fallback

---

## Naming & Code Style Conventions

- Files named exactly after their type: `LoginUiState.swift`, `LoginViewModel.swift`, etc.
- `// MARK: -` sections required in all ViewModels and Screens
- `@MainActor` on all ViewModels and RouteHostViews
- Effects always emitted via `AsyncStream` (preferred) or `PassthroughSubject` — never via `@Published` optional
- All public types explicitly marked `public`
- Stubs prefixed `Demo*`, real implementations have no prefix
- Avoid `// TODO` sprawl — use `// MARK: Firebase – pending` to flag incomplete integration points clearly
