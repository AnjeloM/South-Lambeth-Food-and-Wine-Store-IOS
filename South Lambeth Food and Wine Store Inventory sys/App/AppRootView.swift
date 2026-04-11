//
//  AppRootView.swift
//  South Lambeth Food and Wine Store Inventory sys
//
//  Created by Mariyan Anjelo on 18/01/2026.
//
import SwiftUI

public struct AppRootView: View {
    @State private var route: AppRoute = .gate
    // MARK: Firebase – pending
    // Replace LocalSessionManager with FirebaseSessionManager once Firebase Auth is wired.
    private let sessionManager: SessionManaging
    private let registrar: UserRegistering

    public init(sessionManager: SessionManaging) {
        self.sessionManager = sessionManager
        self.registrar = FirebaseUserRegistrar()
    }

    // Simple app-level toast state (placeholder UI)
    @State private var toastMessage: String? = nil

    public var body: some View {
        NavigationStack {
            content
                .animation(.easeInOut(duration: 0.50), value: route)
                .overlay(alignment: .bottom) {
                    toastOverlay
                }
        }
        .onOpenURL { url in
            // Deep link: inventorysys://reset?token=<rawToken>
            guard
                url.scheme == "inventorysys",
                url.host == "reset",
                let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
                let token = components.queryItems?.first(where: { $0.name == "token" })?.value,
                !token.isEmpty
            else { return }
            route = .resetPassword(token: token)
        }
    }

    @ViewBuilder
    private var content: some View {
        switch route {
        case .gate:
            GateRouteHostView(sessionChecker: sessionManager) { gateRoute in
                route = (gateRoute == .home) ? .home : .welcome
            }

        case .welcome:
            WelcomeRouteHostView(
                onNavigate: { welcomeRoute in
                    switch welcomeRoute {
                    case .signIn:
                        route = .login
                    }
                }
            )

        case .login:
            LoginRouteHostView(
                authenticator: FirebaseLoginAuthenticator(),
                onNavigateBack: { route = .welcome },
                onNavigateForgotPassword: { route = .resetmail },
                onNavigateSignUp: { route = .signup },
                onNavigateHome: {
                    sessionManager.saveSession()
                    route = .home
                },
                onShowToast: { message in showToast(message) }
            )

        case .resetmail:
            SendResetMailRouteHostView(
                sender: FirebasePasswordResetSender(),
                onNavigateBack: { route = .login },
                onShowToast: { message in showToast(message) }
            )

        case let .resetPassword(token):
            ResetPasswordRouteHostView(
                token: token,
                resetter: FirebasePasswordResetter(),
                onNavigateToLogin: { route = .login },
                onShowToast: { message in showToast(message) }
            )

        case .signup:
            SignUpRouteHostView(
                otpSender: FirebaseSignUpOtpSender(),
                onNavigateBack: { route = .login },
                onOpenURL: { _ in /* later: open safari */ },
                onNavigateOtp: { email, name, password in
                    route = .otp(email: email, name: name, password: password)
                },
                onContinueWithGoogle: { /* later: google sign-in */  },
                onContinueWithApple: { /* later: apple sign-in */  }
            )

        case let .otp(email, name, password):
            EmailOtpVerificationRouteHostView(
                email: email,
                service: FirebaseEmailOtpService(),
                onBack: { route = .signup },
                onVerified: {
                    Task {
                        do {
                            try await registrar.register(email: email, name: name, password: password)
                            sessionManager.saveSession()
                            route = .home
                        } catch {
                            showToast("Registration failed: \(error.localizedDescription)")
                        }
                    }
                },
                onToast: { message in showToast(message) }
            )
        case .home:
            HomeRouteHostView {
                sessionManager.clearSession()
                route = .welcome
            }
        }
    }

    // MARK: - Toast (temporary, front-end only)

    @ViewBuilder
    private var toastOverlay: some View {
        if let msg = toastMessage {
            Text(msg)
                .font(.subheadline)
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .background(.ultraThinMaterial)
                .clipShape(Capsule(style: .continuous))
                .padding(.bottom, 18)
                .transition(.move(edge: .bottom).combined(with: .opacity))
        }
    }

    @MainActor
    private func showToast(_ message: String) {
        toastMessage = message

        // Auto-hide after 2 seconds (simple UI-only behavior)
        Task {
            try? await Task.sleep(nanoseconds: 2_000_000_000)
            if toastMessage == message {
                toastMessage = nil
            }
        }
    }
}

#Preview("AppRoot - Signed Out -> Welcome") {
    AppRootView(sessionManager: LocalSessionManager())
}

#Preview("AppRoot = Signed In -> Home") {
    AppRootView(sessionManager: LocalSessionManager())
}

