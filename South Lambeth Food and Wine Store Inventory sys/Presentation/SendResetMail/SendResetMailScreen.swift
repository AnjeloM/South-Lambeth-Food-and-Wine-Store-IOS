import SwiftUI

public struct SendResetMailScreen: View {
    public let state: SendResetMailUiState
    public let onEvent: (SendResetMailUiEvent) -> Void

    public init(
        state: SendResetMailUiState,
        onEvent: @escaping (SendResetMailUiEvent) -> Void
    ) {
        self.state = state
        self.onEvent = onEvent
    }

    public enum Field: Hashable { case email }
    @FocusState private var focusedField: Field?

    @Environment(\.colorScheme) private var scheme

    public var body: some View {
        ZStack {
            AppTheme.Colors.background(scheme).ignoresSafeArea()

            VStack(alignment: .leading, spacing: 0) {
                AppTopBar(
                    title: "Reset Email",
                    showBack: true,
                    showsShadow: true
                ) {
                    onEvent(.onbackTapped)
                }

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 12) {
                        OutlinedTextField(
                            title: state.emailLabel,
                            text: Binding(
                                get: { state.email },
                                set: { onEvent(.emailChanged($0)) }
                            ),
                            keyboard: .default,
                            textContentType: .emailAddress,
                            autocapitalization: .words
                        )
                        .focused($focusedField, equals: .email)
                        .submitLabel(.next)
                        .onSubmit { focusedField = .email }
                    }
                    .padding(.horizontal, 18)
                    .padding(.top, 60)
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

        .safeAreaInset(edge: .bottom) {
            bottomBar
        }
    }

    private var bottomBar: some View {
        VStack(spacing: 8) {
            AppPillButton(
                title: "Resend Reset mail",
                isEnabled: state.isResendEnabled
            ) {
                onEvent(.resendTapped)
            }

            if let text = state.cooldownText {
                Text("Resend mail in: \(text) s")
                    .font(.footnote)
                    .foregroundStyle(AppTheme.Colors.secondaryText(scheme))
                    .frame(maxWidth: .infinity, alignment: .center)
            }
        }
        .padding(.horizontal, 18)
        .padding(.top, 10)
        .padding(.bottom, 10)
        .background(AppTheme.Colors.background(scheme).opacity(0.98))
    }
}
// MARK: - Preview

#Preview("Reset Password - Light") {
    NavigationStack {
        SendResetMailScreen(
            state: {
                var s = SendResetMailUiState()
                s.emailLabel = "Email"
                s.email = "anjelom.1990@gmail.com"
                s.isResendEnabled = true
                s.title = "Reset Password"
                return s
            }(),
            onEvent: { _ in }
        )
        .preferredColorScheme(.light)
    }
}
