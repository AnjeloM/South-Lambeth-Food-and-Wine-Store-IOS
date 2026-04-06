import SwiftUI

public struct LoginScreen: View {
    public var state: LoginUiState
    public var onEvent: (LoginUiEvent) -> Void

    @Environment(\.colorScheme) private var scheme

    // Keyboard management (UI0only concern, fine to keep local)
    private enum FocusField { case email, password }
    @FocusState private var focusedField: FocusField?

    public init(
        state: LoginUiState,
        onEvent: @escaping (LoginUiEvent) -> Void
    ) {
        self.state = state
        self.onEvent = onEvent
    }

    public var body: some View {
        ZStack {
            AppTheme.Colors.background(scheme)
                .ignoresSafeArea()

            VStack(alignment: .leading, spacing: 0) {
                AppTopBar(
                    title: state.title,
                    showBack: true,
                    showsShadow: true,
                ) {
                    onEvent(.onbackTapped)
                }

                ScrollView(showsIndicators: false) {
                    content

                    Spacer().frame(height: 42)

                    bottomArea
                }
                .padding(.horizontal, 18)
                .padding(.top, 10)
                .padding(.bottom, 18)
                .onAppear { onEvent(.onAppear) }
                // Tap outside to dismiss keyboard
                .contentShape(Rectangle())
                .onTapGesture {
                    focusedField = nil
                    dismissKeyboard()
                }
            }
        }
    }

    // MARK: Binding that dispath events (keep UI dumb
    private var emailBinding: Binding<String> {
        Binding(
            get: { state.email },
            set: { onEvent(.emailChanged($0)) }
        )
    }

    private var passwordBinding: Binding<String> {
        Binding(
            get: { state.password },
            set: { onEvent(.passwordChanged($0)) }
        )
    }

    // MARK: Top Bar
    private var topBar: some View {
        HStack(spacing: 12) {
            Button {
                onEvent(.onbackTapped)
            } label: {
                Image(systemName: "chevron.left")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(AppTheme.Colors.primaryText(scheme))
                    .frame(width: 44, height: 44)
            }
            .buttonStyle(.plain)

            Spacer()

            Text(state.title)
                .font(.system(size: 22, weight: .semibold))
                .foregroundStyle(AppTheme.Colors.primaryText(scheme))

            Spacer()

            Color.clear.frame(width: 44, height: 44)
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
                text: emailBinding,
                keyboard: .emailAddress,
                textContentType: .emailAddress,
                autocapitalization: .never,
                accessibilityLabel: "Email",
            )

            OutlinedPasswordField(
                title: state.passwordLabel,
                text: passwordBinding,
                isVisible: state.isPasswordVisible,
                accessibilityLabel: "Password",
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
    private let state = LoginUiState()

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
