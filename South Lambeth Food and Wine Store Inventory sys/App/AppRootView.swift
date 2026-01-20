//
//  AppRootView.swift
//  South Lambeth Food and Wine Store Inventory sys
//
//  Created by Mariyan Anjelo on 18/01/2026.
//
import SwiftUI

public struct AppRootView: View {
    @State private var route: AppRoute = .gate
    // Demo seesion checker for now. Replace with firebaseSessionChecker later.
    private let sessionChecker: SessionChecking

    public init(sessionChecker: SessionChecking) {
        self.sessionChecker = sessionChecker
    }

    public var body: some View {
        NavigationStack {
            content
                .animation(.easeInOut(duration: 0.50), value: route)
        }
    }

    @ViewBuilder
    private var content: some View {
        switch route {
        case .gate:
            GateRouteHostView(sessionChecker: sessionChecker) { gateRoute in
                route = (gateRoute == .home) ? .home : .welcome
            }

        case .welcome:
            WelcomeRouteHostView { welcomeRoute in
                switch welcomeRoute {
                case .signIn:
                    route = .login
                }
            }

        case .login:
            LoginRouteHostView(
                onNavigateBack: { route = .welcome },
                onNavigateForgotPassword: { /* route = .forgotPassword (later) */ },
                onNavigateSignUp: { /* route = .signUp (later) */  },
                onNavigateHome: { route = .home }
            )

        case .home:
            HomeRouteHostView {
                route = .welcome
            }
        }
    }
}

#Preview("AppRoot - Signed Out -> Welcome") {
    AppRootView(sessionChecker: DemoSessionChecker(signedIn: false))
}

#Preview("AppRoot = Signed In -> Home") {
    AppRootView(sessionChecker: DemoSessionChecker(signedIn: true))
}
