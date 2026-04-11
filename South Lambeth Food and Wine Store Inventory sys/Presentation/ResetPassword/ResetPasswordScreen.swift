import SwiftUI

public struct ResetPasswordScreen: View {
    public let state: ResetPasswordUiState
    public let onEvent: (ResetPasswordUiEvent) -> Void

    public init(
        state: ResetPasswordUiState,
        onEvent: @escaping (ResetPasswordUiEvent) -> Void
    ) {
        self.state = state
        self.onEvent = onEvent
    }

    @Environment(\.colorScheme) private var scheme

    private enum Field: Hashable { case newPassword, confirmPassword }
    @FocusState private var focused: Field?

    public var body: some View {
        ZStack {
            AppTheme.Colors.background(scheme)
                .ignoresSafeArea()

            VStack(alignment: .leading, spacing: 0) {
                AppTopBar(title: state.title, showBack: false, showsShadow: true) {}

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 14) {
                        Spacer().frame(height: 32)

                        OutlinedPasswordField(
                            title: state.newPasswordLabel,
                            text: Binding(
                                get: { state.newPassword },
                                set: { onEvent(.newPasswordChanged($0)) }
                            ),
                            isVisible: state.isPasswordVisible,
                            onToggleVisibility: { onEvent(.toggleNewPasswordVisibility) }
                        )
                        .focused($focused, equals: .newPassword)
                        .submitLabel(.next)
                        .onSubmit { focused = .confirmPassword }

                        OutlinedPasswordField(
                            title: state.confirmPasswordLabel,
                            text: Binding(
                                get: { state.confirmPassword },
                                set: { onEvent(.confirmPasswordChanged($0)) }
                            ),
                            isVisible: state.isConfirmPasswordVisible,
                            onToggleVisibility: { onEvent(.toggleConfirmPasswordVisibility) }
                        )
                        .focused($focused, equals: .confirmPassword)
                        .submitLabel(.done)
                        .onSubmit {
                            focused = nil
                            dismissKeyboard()
                        }

                        if let error = state.errorMessage {
                            Text(error)
                                .font(.footnote)
                                .foregroundStyle(AppTheme.Colors.error(scheme))
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(.horizontal, 4)
                        }

                        passwordRules
                    }
                    .padding(.horizontal, 18)
                    .padding(.bottom, 18)
                }
                .scrollDismissesKeyboard(.interactively)
                .onAppear { onEvent(.onAppear) }
                .toolbar {
                    ToolbarItemGroup(placement: .keyboard) {
                        Spacer()
                        Button("Done") {
                            focused = nil
                            dismissKeyboard()
                        }
                    }
                }
            }
        }
        .safeAreaInset(edge: .bottom) {
            AppPillButton(
                title: state.isLoading ? "Saving..." : "Set New Password",
                isLoading: state.isLoading,
                isEnabled: state.isSubmitEnabled,
                action: { onEvent(.submitTapped) }
            )
            .padding(.horizontal, 18)
            .padding(.vertical, 12)
            .background(AppTheme.Colors.background(scheme).opacity(0.98))
        }
    }

    // MARK: Password Rules

    private var passwordRules: some View {
        VStack(alignment: .leading, spacing: 8) {
            ForEach([
                "At least 8 characters",
                "2 uppercase and 2 lowercase letters",
                "At least 1 number",
                "At least 1 special character (e.g. !, @, #)"
            ], id: \.self) { rule in
                HStack(alignment: .top, spacing: 8) {
                    Text("•")
                        .foregroundStyle(AppTheme.Colors.secondaryText(scheme))
                    Text(rule)
                        .font(.footnote)
                        .foregroundStyle(AppTheme.Colors.secondaryText(scheme))
                }
            }
        }
        .padding(.top, 4)
    }
}

// MARK: - Previews

#Preview("ResetPassword Screen - Light") {
    ResetPasswordScreen(
        state: ResetPasswordUiState(token: "preview-token"),
        onEvent: { _ in }
    )
    .preferredColorScheme(.light)
}

#Preview("ResetPassword Screen - Dark") {
    ResetPasswordScreen(
        state: ResetPasswordUiState(token: "preview-token"),
        onEvent: { _ in }
    )
    .preferredColorScheme(.dark)
}
