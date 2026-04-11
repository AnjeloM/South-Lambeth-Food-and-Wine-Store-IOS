import SwiftUI

public struct SignUpScreen: View {
    public let state: SignUpUiState
    public let onEvent: (SignUpUiEvent) -> Void

    public init(
        state: SignUpUiState,
        onEvent: @escaping (SignUpUiEvent) -> Void
    ) {
        self.state = state
        self.onEvent = onEvent
    }

    @Environment(\.colorScheme) private var scheme

    private enum Field: Hashable {
        case name, email, password, retypePassword
    }

    @FocusState private var focusedField: Field?

    public var body: some View {
        ZStack {
            AppTheme.Colors.background(scheme)
                .ignoresSafeArea()

            VStack(alignment: .leading, spacing: 0) {
                AppTopBar(
                    title:  state.title,
                    showBack: true,
                    showsShadow: true,
                    
                ) {
                    onEvent(.onbackTapped)
                }

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 12) {
                        OutlinedTextField(
                            title: state.nameLabel,
                            text: Binding(
                                get: { state.name },
                                set: { onEvent(.nameChanged($0)) }
                            ),
                            keyboard: .default,
                            textContentType: .name,
                            autocapitalization: .words
                        )
                        .focused($focusedField, equals: .name)
                        .submitLabel(.next)
                        .onSubmit { focusedField = .email }

                        VStack(alignment: .leading, spacing: 4) {
                            OutlinedTextField(
                                title: state.emailLabel,
                                text: Binding(
                                    get: { state.email },
                                    set: { onEvent(.emailChanged($0)) }
                                ),
                                keyboard: .emailAddress,
                                textContentType: .emailAddress,
                                autocapitalization: .never
                            )
                            .focused($focusedField, equals: .email)
                            .submitLabel(.next)
                            .onSubmit { focusedField = .password }

                            if let emailError = state.emailError {
                                Text(emailError)
                                    .font(.caption)
                                    .foregroundStyle(AppTheme.Colors.error(scheme))
                                    .padding(.horizontal, 4)
                            }
                        }

                        OutlinedPasswordField(
                            title: state.passwordLabel,
                            text: Binding(
                                get: { state.password },
                                set: { onEvent(.passwordChanged($0)) }
                            ),
                            isVisible: state.isPasswordVisible,
                            onToggleVisibility: {
                                onEvent(.togglePasswordVisibility)
                            }
                        )
                        .focused($focusedField, equals: .password)
                        .submitLabel(.next)
                        .onSubmit { focusedField = .retypePassword }

                        OutlinedPasswordField(
                            title: state.retypePasswordLabel,
                            text: Binding(
                                get: { state.retypePassword },
                                set: { onEvent(.retypePasswordChanged($0)) }
                            ),
                            isVisible: state.isRetypePasswordVisible,
                            onToggleVisibility: {
                                onEvent(.toggleRetypePasswordVisibility)
                            }
                        )
                        .focused($focusedField, equals: .retypePassword)
                        .submitLabel(.done)
                        .onSubmit {
                            focusedField = nil
                            dismissKeyboard()
                        }

                        passwordRules
                    }
                    Spacer(minLength: 0)

                    VStack(spacing: 12) {
                        AppPillButton(
                            title: state.signUpButtonText,
                            isLoading: state.isLoading,
                            isEnabled: !state.isLoading
                        ) {
                            onEvent(.signUpTapped)
                        }

                        AppPillButton(
                            title: state.googleButtonText,
                            icon: .custom(AnyView(GoogleGlyph()))
                        ) {
                            onEvent(.googleTapped)
                        }

                        // orDivider

                        AppPillButton(
                            title: state.appleButtonText,
                            icon: .system("apple.logo")
                        ) {
                            onEvent(.appleTapped)
                        }
                    }

                    footer
                        .padding(.top, 12)
                }
                .padding(.horizontal, 18)
                .padding(.top, 10)
                .padding(.bottom, 18)
                .onAppear { onEvent(.onAppear) }
            }
            .scrollDismissesKeyboard(.interactively)
            .simultaneousGesture(
                TapGesture().onEnded {
                    focusedField = nil
                    dismissKeyboard()
                }
            )
            .toolbar {
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button("Done") {
                        focusedField = nil
                        dismissKeyboard()
                    }
                }
            }
        }
    }

    // MARK: Password Rules
    private var passwordRules: some View {
        VStack(alignment: .leading, spacing: 8) {
            ForEach(state.passwordRules, id: \.self) { rule in
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
        .padding(.bottom, 8)
    }

    // MARK: orDivider
    private var orDivider: some View {
        HStack(spacing: 12) {
            Rectangle()
                .fill(AppTheme.Colors.fieldBorder(scheme))
                .frame(height: 1)

            Text("OR")
                .font(.footnote.weight(.semibold))
                .foregroundStyle(AppTheme.Colors.secondaryText(scheme))

            Rectangle()
                .fill(AppTheme.Colors.fieldBorder(scheme))
                .frame(height: 1)
        }
        .padding(.horizontal, 8)
    }

    // MARK: Footer
    private var footer: some View {
        VStack(spacing: 6) {
            Text(state.footerPrefixText)
                .font(.footnote)
                .foregroundStyle(AppTheme.Colors.secondaryText(scheme))

            VStack(spacing: 4) {
                Text("\(state.footerBrandText)'s")
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(AppTheme.Colors.accent(scheme))

                HStack(spacing: 6) {
                    Button(state.privacyPolicyText) {
                        onEvent(.privacyPolicyTapped)
                    }
                    .buttonStyle(.plain)
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(AppTheme.Colors.accent(scheme))
                    .underline()

                    Text(state.andText)
                        .font(.footnote)
                        .foregroundStyle(AppTheme.Colors.secondaryText(scheme))

                    Button(state.termsText) { onEvent(.termsTapped) }
                        .buttonStyle(.plain)
                        .font(.footnote.weight(.semibold))
                        .foregroundStyle(AppTheme.Colors.accent(scheme))
                        .underline()
                }
            }
            .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .multilineTextAlignment(.center)
    }
}

// MARK: - Google glyph (temporary; replace later with real logo asset)

private struct GoogleGlyph: View {
    var body: some View {
        ZStack {
            Circle()
                .fill(Color.black.opacity(0.12))
                .frame(width: 30, height: 30)

            Text("G")
                .font(.system(size: 16, weight: .black))
                .foregroundStyle(.black)
        }
        .accessibilityHidden(true)
    }
}

// MARK: - Preview

#Preview("SignUp - Light") {
    SignUpScreen(
        state: {
            var s = SignUpUiState()
            s.name = "Anjelo"
            s.email = "anjelo@example.com"
            s.password = "••••••••••"
            s.retypePassword = "••••••••••"
            return s
        }(),
        onEvent: { _ in }
    )
    .preferredColorScheme(.light)
}

#Preview("SignUp - Dark") {
    SignUpScreen(
        state: {
            var s = SignUpUiState()
            s.name = "Anjelo"
            s.email = "anjelo@example.com"
            s.password = "••••••••••"
            s.retypePassword = "••••••••••"
            return s
        }(),
        onEvent: { _ in }
    )
    .preferredColorScheme(.dark)
}

