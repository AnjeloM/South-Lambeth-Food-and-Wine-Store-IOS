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
  └── unauthenticated → Welcome → Login / SignUp → (OTP) → Home
                                 → ForgotPassword → SendResetMail → (OTP)
```

### Rules

- `AppRoute` (enum in `App/AppRoute.swift`) is the only navigation source of truth
- `AppRootView` holds `@State var route: AppRoute` and `switch`es on it to render the active `RouteHostView`
- Navigation is **always triggered via Effects**: Screen emits event → VM emits effect → RouteHostView catches it → calls injected closure → AppRootView updates `route`
- There is **no `NavigationLink` or `NavigationStack` push/pop** — all transitions are root-level swaps animated with `.easeInOut(duration: 0.50)`
- Views must **never** control navigation directly

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

Firebase integration is **not yet connected**. Current stubs:

| Protocol | Stub | Status |
|---|---|---|
| `SessionChecking` | `DemoSessionChecker` | Hardcoded bool |
| `EmailOtpServicing` | `DemoEmailOtpService` | Accepts `"123456"` / `"1234"` in previews |
| `TestEmailSending` | `DemoTestEmailSender` | Simulates 600ms latency |
| `FirebaseCallableTestEmailSender` | (empty file) | Implementation pending |

When wiring Firebase, replace `Demo*` implementations and inject them at `AppRootView`.

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

### Security Rules (client-side)

- Never perform OTP validation on-device — always call the Cloud Function
- Never store raw tokens in UserDefaults — always use Keychain
- Never expose Firebase project secrets in source code
- Firestore rules must enforce TTL on temporary secure documents (OTP records, reset tokens)

---

## UI Components (Shared)

All reusable UI lives in `Shared/`. When building new screens, use existing components before creating new ones.

| Component | File |
|---|---|
| `AppPillButton` | Primary CTA button, supports loading state and disabled state |
| `OutlinedTextField` | Labelled text input with border, keyboard type, content type |
| `OutlinedPasswordField` | Password input with visibility toggle |
| `AppTopBar` | Screen title bar with optional back button and shadow |

When adding new shared components:
- Accept state via plain value parameters (not bindings where avoidable)
- Emit actions via closures
- Use `AppTheme` exclusively for styling
- Always include a `#Preview`

### Home Screen Requirements (upcoming)

The Home screen must reflect real shop operations:

- Inventory statistics (total items, total value, low stock count)
- Stock overview by category
- Filters (category, low stock, expiry, etc.)
- Recent stock updates / audit log
- Product quick actions (scan barcode, add item, export PDF)

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