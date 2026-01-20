//
//  SignInRouteHostView.swift
//  South Lambeth Food and Wine Store Inventory sys
//
//  Created by Mariyan Anjelo on 19/01/2026.
//
import SwiftUI

@MainActor
public struct LoginRouteHostView: View {
    @StateObject private var viewModel = LoginViewModel()
    
    private let onNavigateBack: () -> Void
    private let onNavigateForgotPassword: () -> Void
    private let onNavigateSignUp: () -> Void
    private let onNavigateHome: () -> Void

    public init(
        viewModelFactory: @MainActor @autoclosure @escaping () -> LoginViewModel = LoginViewModel(),
        onNavigateBack: @escaping () -> Void = {},
        onNavigateForgotPassword: @escaping () -> Void = {},
        onNavigateSignUp: @escaping () -> Void = {},
        onNavigateHome: @escaping () -> Void = {}
    ) {
        _viewModel = StateObject(wrappedValue: viewModelFactory())
        self.onNavigateBack = onNavigateBack
        self.onNavigateForgotPassword = onNavigateForgotPassword
        self.onNavigateSignUp = onNavigateSignUp
        self.onNavigateHome = onNavigateHome
    }

    public var body: some View {
        LoginScreen(
            state: viewModel.state,
            onEvent: viewModel.onEvent
        )
        .task {
            for await effect in viewModel.effects {
                handle(effect)
            }
        }
    }

    private func handle(_ effect: LoginUiEffect) {
        switch effect {
        case .navigateBack:
            onNavigateBack()

        case .navigateForgotPassword:
            onNavigateForgotPassword()

        case .navigateSignUp:
            onNavigateSignUp()

        case .navigateHome:
            onNavigateHome()
        }
    }
}

#Preview("SignInRouteHostView") {
    SignInRouteHostView()
}
