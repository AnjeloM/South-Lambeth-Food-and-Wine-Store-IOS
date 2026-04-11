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
                                    │                       (MARK: Firebase – pending)
                                    ├── ForgotPassword → SendResetMail        │
                                    │                     (email link)         │
                                    │                       → ResetPassword ───┘
                                    └── ← back ← RoleSelection / SignUp
```

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
- `sessionManager.saveSession()` — on successful login (`onNavigateHome`) and OTP verification (`onVerified`)
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
| **Google Cloud Functions** | Backend logic: OTP generation, token validation, password reset |
| **Cloudinary** | Product image and file storage |

### Backend Responsibilities (never implement client-side)

- Email OTP generation and verification
- Password reset token creation and validation
- Token hashing, salting, and TTL enforcement
- Any sensitive business logic that must not live in the client

### Firebase Status

Auth flows are substantially wired. One stub remains pending a Firebase Auth swap.

| Flow | Protocol | Production impl | File | Status |
|---|---|---|---|---|
| Session check / save / clear | `SessionManaging` | `LocalSessionManager` | `Domain/Session/` | **Pending** — UserDefaults; swap for `FirebaseSessionManager` |
| Login | `LoginAuthenticating` | `FirebaseLoginAuthenticator` | `Domain/Firebase/` | Wired — `Auth.auth().signIn` |
| Register user | `UserRegistering` | `FirebaseUserRegistrar` | `Domain/Firebase/` | Wired — `registerUser` Cloud Function |
| Send sign-up OTP | `SignUpOtpSending` | `FirebaseSignUpOtpSender` | `Presentation/SignUp/SignUpDependencies.swift` | Wired — `sendEmailOtp` Cloud Function |
| Verify OTP | `EmailOtpServicing` | `FirebaseEmailOtpService` | `Domain/Firebase/` | Wired — `verifyEmailOtp` Cloud Function |
| Send password reset email | `PasswordResetSending` | `FirebasePasswordResetSender` | `Domain/Firebase/` | Wired — `requestPasswordResetLink` Cloud Function |
| Reset password with token | `PasswordResetting` | `FirebasePasswordResetter` | `Domain/Firebase/` | Wired — `resetPasswordWithToken` Cloud Function |

`Demo*` stubs exist for every protocol — previews and unit tests only. Never use them in `AppRootView`.

**Remaining Firebase swap:** Replace `LocalSessionManager` in `ContentView.swift` with a `FirebaseSessionManager` that reads `Auth.auth().currentUser != nil`. No other file needs to change.

### Deployed Cloud Functions (`functions/src/index.ts`, region: `europe-north1`)

| Function | Purpose |
|---|---|
| `sendEmailOtp` | Generates 4-digit OTP, hashes+salts, stores in `email_otp` Firestore collection, sends via AWS SES |
| `verifyEmailOtp` | Re-hashes entered OTP with stored salt, timing-safe compare, deletes record on success |
| `registerUser` | Creates Firebase Auth user + writes `users` Firestore document |
| `requestPasswordResetLink` | Generates secure token, hashes+salts, stores in `password_reset_tokens`, sends deep link email |
| `resetPasswordWithToken` | Validates token, updates Firebase Auth password, invalidates token |
| `sendTestEmail` | Retained in backend — not called from iOS app |

AWS SES is **out of sandbox** — all functions send to any email address.

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
  - Group 1 (nav): Profile, Report, TimeSheet, History, Terms & Conditions
  - Group 2 (print): Set Print Order, Print
- Bottom: Logout row pinned below a `Divider`, styled in `AppTheme.Colors.error(scheme)`

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
| `EmailOtpVerificationRouteHostView` | `state.isVerifying` |
| `SendResetMailRouteHostView` | `state.isSubmitting` |
| `ResetPasswordRouteHostView` | `state.isLoading` |

The inline OTP registration `Task` in `AppRootView` (`.otp` case) sets `isBlocking` directly before/after `registrar.register(...)`.

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

Frontend-only onboarding screen for store owners. Files: `Presentation/OwnerSignUp/` (full 5-file contract).

**Features:**
- Account details section: Name, Email, Password, Retype Password (same password rules as user signup)
- **Shop list section** — owner must add at least one shop before submitting
- Each shop entry: Name, Address, Phone (UK-style mask `XXXXX XXXXXX`), Location (tappable stub — `// MARK: Firebase – pending` for Google Maps picker storing `latitude`/`longitude`)
- **Add/Edit shop** via `ShopFormSheet` (private sheet in `OwnerSignUpScreen.swift`) — name and address are required; phone and location are optional
- **Delete shop** requires typing `CONFIRM` exactly in `DeleteConfirmSheet` before the Remove button activates; button animates from disabled (grey) → enabled (red)

**Key models (defined in `OwnerSignUpUiState.swift`):**

| Type | Role |
|---|---|
| `OwnerShopEntry` | `id`, `name`, `address`, `phone` (masked), `locationLabel`, `latitude?`, `longitude?` |
| `OwnerSignUpUiState` | Account fields, `shops: [OwnerShopEntry]`, sheet presentation flags (`isShopSheetPresented`, `isDeleteConfirmPresented`), `draftShop`, `deleteConfirmText`, `isDeleteConfirmValid` |

**Pending (`// MARK: Firebase – pending`):**
- `OwnerSignUpUiEffect` has only `navigateBack` and `showToast` — no OTP/registration flow yet
- `submit()` validates all fields, then shows a toast; replace with OTP + owner-registration Cloud Function when backend is wired
- `draftShopLocationTapped` shows "Location picker coming soon" toast — replace with Google Maps SDK sheet that writes `locationLabel`, `latitude`, `longitude`
- Back navigation: `.ownerSignUp` → `.roleSelection`

### User Sign Up — Store Assignment

`SignUpScreen` now includes a **Store Assignment** card section (below password rules, above the Sign Up button). The user must select an owner and a default shop before the form can be submitted.

**Models (defined in `SignUpUiState.swift`):**

| Type | Role |
|---|---|
| `SignUpOwner` | `id`, `name`, `storeName`, `shops: [SignUpShop]` |
| `SignUpShop` | `id`, `name`, `address` |

**State additions to `SignUpUiState`:**
- `availableOwners: [SignUpOwner]` — populated from `mockOwners` (3 owners, 5 shops); replace with Firestore query
- `selectedOwner: SignUpOwner?`, `selectedShop: SignUpShop?`
- `isOwnerPickerPresented: Bool`, `isShopPickerPresented: Bool`

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
- The current `registrar.register()` call in `AppRootView` is a placeholder — replace with a join-request Cloud Function

**Social sign-in buttons (Google / Apple):**  
Commented out in `SignUpScreen.swift` — not removed, ready to re-enable once OAuth is wired.

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
- Replace mock items and `weeksWithInventory` with `InventoryRepository` Firestore calls

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