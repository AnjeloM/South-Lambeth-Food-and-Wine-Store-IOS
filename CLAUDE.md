# CLAUDE.md
Compact repo guide for Claude Code. Keep architecture and product intent intact; avoid speculative rewrites.
## Build & Test
Open: `open "South Lambeth Food and Wine Store Inventory sys.xcodeproj"`
Build: `xcodebuild -project "South Lambeth Food and Wine Store Inventory sys.xcodeproj" -scheme "South Lambeth Food and Wine Store Inventory sys" -destination "platform=iOS Simulator,name=iPhone 16" build`
Test: `xcodebuild test -project "South Lambeth Food and Wine Store Inventory sys.xcodeproj" -scheme "South Lambeth Food and Wine Store Inventory sys" -destination "platform=iOS Simulator,name=iPhone 16"`
## Product Goal
Production-ready iOS inventory system for a food, wine, and off-licence store.
Every change should support:
- offline + online sync readiness
- Firebase / Cloud Functions / Cloudinary integration
- secure auth, OTP, and password reset
- media uploads
- future AI-assisted features
## Core Architecture
Use strict MVVM + MVI.
Rules:
- ViewModel is the single source of truth
- Views render state and emit events only
- no business logic in Views
- effects are one-time actions only: navigation, toasts, alerts, URLs, dialogs
Project layers:
- `App/`: entry point and routing
- `Presentation/`: screen folders
- `Domain/`: protocols and concrete services
- `Shared/`: reusable UI
- `UI/`: `AppTheme`
## Screen Contract
Preferred per screen:
- `*UiState`: plain display struct
- `*UiEvent`: user intents
- `*UiEffect`: one-off side effects
- `*ViewModel`: `@MainActor final class ObservableObject`
- `*RouteHostView`: owns `@StateObject`, bridges effects outward
- `*Screen`: pure SwiftUI view with `state` + `onEvent`
Simple screens may collapse contract types into `*Contract.swift`, but keep separation of concerns.
When generating screens:
- keep the full contract unless the screen is trivial
- use `async/await`
- inject protocol types, not concrete types
- add `#Preview`
- use `// MARK:`
## Navigation
Navigation is centralized in `AppRootView` via `AppRoute`.
Rules:
- `AppRoute` is the only routing source of truth
- `AppRootView` owns `@State var route: AppRoute`
- flow is `event -> ViewModel effect -> RouteHostView closure -> route change`
- do not use feature-owned `NavigationStack` / `NavigationLink` flow for app routing
- app transitions are root-level screen swaps
- Views never navigate directly
Main routes:
- `gate`
- `welcome`
- `login`
- `roleSelection`
- `signup`
- `otp(email,name,password)`
- `ownerSignUp`
- `ownerOtp(email,name,password,shops,defaultShopId)`
- `resetmail`
- `resetPassword(token)`
- `home`
All associated route values must remain `Hashable`.
## Session Persistence
Goal: keep users signed in across cold launches until logout.
Current contract in `Domain/Session/SessionChecking.swift`:
- `SessionChecking`: `isSignedIn() async -> Bool`
- `SessionManaging`: adds `saveSession()` and `clearSession()`
- `LocalSessionManager`: temporary `UserDefaults` implementation
Flow:
- `GateViewModel` checks session and routes to `.home` or `.welcome`
- save session after successful login / OTP verification
- clear session on logout
Planned swap: replace `LocalSessionManager` with Firebase-backed session state while keeping callers protocol-typed.
## Dependency Injection
Inject dependencies at `RouteHostView` / `AppRootView`.
Rules:
- prefer protocol-typed dependencies
- keep `Demo*` types in previews, tests, or temporary composition only
- real implementations belong in Domain/Firebase or equivalent concrete layer
## Backend Responsibilities
Keep sensitive operations on the backend:
- OTP generation and verification
- password reset token creation / validation
- token hashing, salting, TTL, and rate limiting
- secure registration flows
- sensitive business rules
Primary services:
- Firebase Auth
- Cloud Firestore
- Cloud Functions
- Cloudinary
## Auth, OTP, and Reset
### OTP
User flow:
- `SignUp` sends OTP
- `otp` verifies OTP
- success continues registration and reaches Home
Owner flow:
- `OwnerSignUp` collects account + shops
- sends OTP
- `ownerOtp` carries `shops` and `defaultShopId`
- success calls `registerOwner` to write user + shops + employee links
Cooldown ladder: `60s -> 2m -> 5m -> 30m -> 1h`
OTP TTL: `300` seconds
Critical no-regression OTP UI rules:
- apply `.textContentType(.oneTimeCode)` only to the first OTP field
- move focus from `.onChange`, not a binding setter
- batch ViewModel state mutations before reassigning state
- keep paste-spread logic in the ViewModel
### Password Reset
Flow:
1. user enters email on `SendResetMail`
2. backend returns neutral response whether email exists or not
3. email contains HTTPS reset link
4. hosting page redirects to the custom scheme
5. app opens `resetPassword(token:)`
6. backend validates token and updates password
7. success returns user to Login
Reset link chain:
- `https://inventory-app-352dc.web.app/reset?token=<rawToken>`
- `inventorysys://reset?token=<rawToken>`
Why the HTTPS hop exists: browsers and email clients do not reliably open raw custom schemes. Xcode requirement: Info -> URL Types -> scheme `inventorysys`
Security rules:
- never verify OTP or reset tokens on-device
- never store raw secure tokens in `UserDefaults`
- use Keychain for sensitive local storage
- keep client and server password rules aligned
- keep reset email responses neutral to prevent account enumeration
## Firestore Model
Canonical schema: `firestore/firestore_schema_spec.json`
Consult it before changing fields; update schema and backend writers together.
Main collections:
- `users`
- `shops`
- `pendingRequests`
- `employees`
- `items`
- `inventory`
- `purchaseRequests`
- `timesheets`
- `notifications`
Internal function-only collections:
- `email_otp`
- `password_reset_tokens`
- `password_reset_rate`
Important field concepts:
- `users.role`: `owner`, `supervisor`, `admin`, `standard`
- `users.shopIDs`: assigned shops
- `users.currentShopID`: current active shop across devices
- `shops.isDefault`: owner-designated default shop
## Active Shop Rules
Active shop is a core concept and should scope future inventory behavior.
Load priority:
1. `users/{uid}.currentShopID`
2. cached `UserDefaults("app.activeShopId")`
3. shop with `isDefault == true`
4. first shop
Requirements:
- switching shop updates Firestore and local cache
- deleting an active shop must promote another shop safely
- future inventory queries must be scoped by current shop
## Main Screens
### Gate / Welcome / Login
- `Gate` checks session
- `Welcome` is unauthenticated landing
- `Login` authenticates and saves session
### Role Selection
- sits between Login and Sign Up
- user picks `User` or `Owner`
- routes to `.signup` or `.ownerSignUp`
### User Sign Up
- standard fields plus store assignment
- user must choose an owner and a shop before submit
- owners load via `OwnerFetching`
- selected owner/shop currently feeds signup flow
- future post-OTP behavior should create a `pendingRequests` join request
Important models: `SignUpOwner(id,name,storeName,shops)`, `SignUpShop(id,name,address)`
### Owner Sign Up
- owner enters account details
- owner must add at least one shop
- owner selects a default shop
- add/edit shop sheet supports name, address, phone, future location picker
- delete shop requires typing `CONFIRM`
Keep `OwnerShopEntry` hashable because route payloads require it.
### Manage Shop / Switch Shop
Lives in `Presentation/SwitchShop/`.
Behavior:
- owners can add, edit, delete, and set default shops
- standard users can switch among assigned shops
Rules:
- owner default toggle writes `shops.isDefault` and updates active shop
- user switch should confirm before changing current shop
- delete should guard against removing the last shop
- `currentShopID` is cross-device truth
`ShopManaging` remains the abstraction for load/add/update/remove/default/current shop operations.
### Home
`HomeState` currently stores selected tab only.
Tabs: dashboard placeholder, inventory, report, categories.
Logout must stay in `AppDrawer`, not on the dashboard.
### Inventory
Inventory already follows the MVI contract.
Current behavior:
- week-based context
- create/edit CTA depends on whether selected week has inventory
- filter cards for total, low stock, out of stock
- search support
- mock data for now
Future:
- replace mock data with `InventoryRepository`
- wire create/edit flows through effects and routes
### Scanner
Rules:
- root uses `.ignoresSafeArea()`
- top padding must use real device safe-area inset, never a hardcoded value
## Shared UI
Reuse existing shared components before creating new ones:
- `AppPillButton`
- `OutlinedTextField`
- `OutlinedPasswordField`
- `AppTopBar`
- `AppScreenHeader`
- `AppSearchFilterBar`
- `AppBottomNavBar`
- `AppDrawer`
- `AppLoadingOverlay`
### AppDrawer
Drawer is a key interaction hub.
Must support:
- profile header
- menu items including Manage Shop
- print actions
- logout at bottom
Important wiring:
- logout flows `AppDrawer -> HomeEvent.onSignOutTapped -> ViewModel effect -> host closure -> clear session -> .welcome`
- drawer open/close is local UI state in `HomeScreen`, not ViewModel state
### AppLoadingOverlay
Global blocking overlay used during async actions before route changes.
Rules:
- RouteHostViews bridge loading flags upward
- overlay blocks interaction
- use it for login, signup, OTP verify, reset password, and registration transitions
## Theming
All visual constants live in `UI/AppTheme.swift`.
Never hardcode colors, spacing, fonts, or theme radii where `AppTheme` already defines them.
Namespaces:
- `AppTheme.Colors`
- `AppTheme.Typography`
- `AppTheme.Layout`
Theme rules:
- use `surfaceContainer` for cards, bars, and fields
- use `.ultraThinMaterial` for floating/overlay surfaces
- accent fill is for key CTAs only
- avoid ad hoc hex values and inverted-color shortcuts
Brand accent:
- light: `#6B57A7`
- dark: `#D6D000`
## Data Layer Direction
Keep the app ready for offline-capable repositories.
Planned abstractions:
- `SessionRepository`
- `AuthRepository`
- `InventoryRepository`
- `ProductRepository`
Guidelines:
- separate remote and local data sources
- support offline queue / sync strategy
- wrap Firebase/network calls behind repositories
- reserve `UserDefaults` for non-sensitive preferences
- use Keychain for secrets and secure session data
## Retail API Direction
External product/barcode lookup should live behind `ProductRepository`.
Possible sources: UK barcode/product datasets, product metadata/image APIs, Open Food Facts fallback.
## Code Style
Conventions:
- files named after their type
- `@MainActor` on ViewModels and RouteHostViews
- use `AsyncStream` or `PassthroughSubject` for effects, not `@Published` optionals
- mark public types explicitly when they are module-facing
- prefix stubs/mocks with `Demo`
- prefer `// MARK: Firebase - pending` over scattered TODOs
Quality bar:
- do not regress auth/security flows
- preserve route payload semantics
- keep business logic out of SwiftUI Views
- keep the app production-oriented, not demo-oriented
