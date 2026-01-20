//
//  SignInScreen.swift
//  South Lambeth Food and Wine Store Inventory sys
//
//  Created by Mariyan Anjelo on 19/01/2026.
//
import SwiftUI

public struct LoginScreen: View {
    public var state: LoginUiState
    public var onEvent: (LoginUiEvent) -> Void

    @Environment(\.colorScheme) private var scheme

    public init(
        state: LoginUiState,
        onEvent: @escaping (LoginUiEvent) -> Void
    ) {
        self.state = state
        self.onEvent = onEvent
    }

    public var body: some View {
        VStack(spacing: 0) {
            topBar

            content

            Spacer(minLength: 0)

            bottomArea
        }
        .padding(.horizontal, 18)
        .padding(.top, 10)
        .padding(.bottom, 18)
        .onAppear { onEvent(.onAppear) }
    }

    // MARK: Top Bar

    private var topBar: some View {
        ZStack {
            HStack {
                Button {
                    onEvent(.backTapped)
                } label: {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 18, weight: .semibold))
                        .frame(width: 44, height: 44, alignment: .leading)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)

                Spacer()
            }
            Text(state.title)
                .font(AppTheme.Typography.title)
        }
        .padding(.top, 2)
        .padding(.bottom, 10)
    }

    // MARK: Content
    private var content: some View {
        VStack(alignment: .leading, spacing: 14) {
            Spacer().frame(height: 120)

            OutlinedTextField(
                title: state.emailLabel,
                value: state.email,
                keyboard: .emailAddress,
                textContentType: .emailAddress,
                autocapitalization: .never,
                accessibilityLabel: "Email",
                onChanged: { onEvent(.emailChanged($0)) }
            )

            OutlinedPasswordField(
                title: state.passwordLabel,
                value: state.password,
                isVisible: state.isPasswordVisible,
                accessibilityLabel: "Password",
                onChanged: { onEvent(.passwordChanged($0)) },
                onToggleVisibility: { onEvent(.passwordVisibilityTapped) }
            )
            HStack {
                Spacer()
                Button {
                    onEvent(.forgotPasswordTapped)
                } label: {
                    Text(state.forgotPasswordText)
                        .font(AppTheme.Typography.link)
                        .foregroundStyle(AppTheme.Colors.linkText(scheme))
                }
                .buttonStyle(.plain)
            }
            .padding(.top, 2)
        }
    }

    // MARK: Bottom
    private var bottomArea: some View {
        VStack(spacing: 12) {
            AppPillButton(
                title: state.loginButtonText,
                isLoading: false,
                isEnabled: state.isLoginEnabled,
                accessibilityLabel: "Login",
                action: { onEvent(.loginTapped) }
            )

            HStack(spacing: 6) {
                Text(state.signUpLinkPrefixText)
                    .font(AppTheme.Typography.body)
                    .foregroundStyle(AppTheme.Colors.secondaryText(scheme))

                Button {
                    onEvent(.signUpTapped)
                } label: {
                    Text(state.signUpLinkButtonText)
                        .font(AppTheme.Typography.link)
                        .foregroundStyle(AppTheme.Colors.linkText(scheme))
                }
                .buttonStyle(.plain)
            }
            .padding(.bottom, 6)
        }
        .padding(.top, 14)
    }

}

#Preview("LoginScreen - Dark") {
    LoginScreenPreviewHost()
        .preferredColorScheme(.dark)
}

#Preview("LoginScreen - Light") {
    LoginScreenPreviewHost()
        .preferredColorScheme(.light)
}

// MARK: - Preview Host

private struct LoginScreenPreviewHost: View {

    // Sample state (tweak values to test UI)
    private let state = LoginUiState(
        title: "Login",
        email: "anjelom.1990@gmail.com",
        emailLabel: "Email",
        password: "password123",
        passwordLabel: "Password",
        isPasswordVisible: false,
        isLoginEnabled: true,
        forgotPasswordText: "Forgot Password",
        loginButtonText: "Login",
        signUpLinkPrefixText: "Don’t have account?",
        signUpLinkButtonText: "SignUp"
    )

    var body: some View {
        NavigationStack {
            LoginScreen(
                state: state,
                onEvent: { _ in
                    // no-op for preview
                }
            )
        }
    }
}
