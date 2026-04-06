import SwiftUI

public struct EmailOtpVerificationScreen: View {
    public let state: EmailOtpVerificationUiState
    public let onEvent: (EmailOtpVerificationUiEvent) -> Void

    public init(
        state: EmailOtpVerificationUiState,
        onEvent: @escaping (EmailOtpVerificationUiEvent) -> Void
    ) {
        self.state = state
        self.onEvent = onEvent
    }

    @Environment(\.colorScheme) private var scheme

    private enum Field: Hashable { case d0, d1, d2, d3 }
    @FocusState private var focused: Field?

    public var body: some View {
        ZStack {
            AppTheme.Colors.background(scheme)
                .ignoresSafeArea()

            VStack(spacing: 0) {
                AppTopBar(title: state.title, showsShadow: false) {
                    onEvent(.backTapped)
                }

                Spacer()

                VStack(spacing: 18) {
                    Text("OTP verification send to:\n\(state.email)")
                        .font(.system(size: 22, weight: .semibold))
                        .multilineTextAlignment(.center)
                        .foregroundStyle(AppTheme.Colors.primaryText(scheme))

                    otpRow
                }
                Spacer()

                VStack(spacing: 14) {
                    otpActionButton(
                        title: state.isVerifying ? "Verifying..." : "Verify",
                        enabled: state.verifyEnabled,
                        onTap: { onEvent(.verifyTapped) }
                    )

                    otpActionButton(
                        title: "Resend OTP",
                        enabled: state.canResend,
                        onTap: { onEvent(.resendTapped) }
                    )

                    Text(state.resendLabel)
                        .font(.system(size: 16))
                        .foregroundStyle(AppTheme.Colors.secondaryText(scheme))
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 18)
            }
        }
        .contentShape(Rectangle())
        .onTapGesture { dismissKeyboard() }
        .onAppear {
            onEvent(.onAppear)
            if state.otpDigits[0].isEmpty { focused = .d0 }
        }
        .onChange(of: state.otpDigits) { _, digits in
            // Focus progresses based on state (UI-only concern)
            if digits[0].isEmpty {
                focused = .d0
                return
            }
            if digits[1].isEmpty {
                focused = .d1
                return
            }
            if digits[2].isEmpty {
                focused = .d2
                return
            }
            if digits[3].isEmpty {
                focused = .d3
                return
            }
            focused = nil
        }
    }

    private var otpRow: some View {
        HStack(spacing: 14) {
            otpBox(index: 0, field: .d0)
            otpBox(index: 1, field: .d1)
            otpBox(index: 2, field: .d2)
            otpBox(index: 3, field: .d3)
        }
        .padding(.top, 6)
    }

    private func otpBox(index: Int, field: Field) -> some View {
        let binding = Binding(
            get: { state.otpDigits[index] },
            set: { newValue in
                onEvent(.otpChanged(index: index, value: newValue))

                // quick focus hint based on user's action
                let digits = newValue.filter { $0.isNumber }
                if digits.isEmpty {
                    focused = previousField(for: field)
                } else {
                    focused = nextField(for: field)
                }
            }
        )

        return TextField("", text: binding)
            .keyboardType(.numberPad)
            .textContentType(.oneTimeCode)
            .multilineTextAlignment(.center)
            .font(.system(size: 22, weight: .bold))
            .foregroundStyle(AppTheme.Colors.accent(scheme)) 
            .focused($focused, equals: field)
            .frame(width: 74, height: 74)
            .background(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(AppTheme.Colors.accent(scheme))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .strokeBorder(
                        AppTheme.Colors.fieldBorder(scheme),
                        lineWidth: 1
                    )
            )
            .accessibilityLabel("OTP digit \(index + 1)")
    }

    private func nextField(for field: Field) -> Field? {
        switch field {
        case .d0: return .d1
        case .d1: return .d2
        case .d2: return .d3
        case .d3: return nil
        }
    }

    private func previousField(for field: Field) -> Field? {
        switch field {
        case .d0: return nil
        case .d1: return .d0
        case .d2: return .d1
        case .d3: return .d2
        }
    }

    // Grey pill buttons like the screenshots (feature-local)
    private func otpActionButton(
        title: String,
        enabled: Bool,
        onTap: @escaping () -> Void
    ) -> some View {
        Button(action: onTap) {
            Text(title)
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(
                    AppTheme.Colors.primaryText(scheme)
                        .opacity(enabled ? 0.55 : 0.25)
                )
                .frame(maxWidth: .infinity)
                .frame(height: 58)
                .background(
                    RoundedRectangle(cornerRadius: 28, style: .continuous)
                        .fill(AppTheme.Colors.accent(scheme))
                )
        }
        .buttonStyle(.plain)
        .disabled(!enabled)
    }

}
