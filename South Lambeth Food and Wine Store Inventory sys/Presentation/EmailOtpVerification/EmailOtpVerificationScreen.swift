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

    private enum Field: Hashable {
        case d0, d1, d2, d3
    }

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
        .toolbar {
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                Button("Done") {
                    focused = nil
                }
            }
        }
        .background(Color.clear.contentShape(Rectangle()).onTapGesture {
            focused = nil
        })
        .onAppear {
            onEvent(.onAppear)
            if focused == nil && state.otpDigits[0].isEmpty {
                focused = .d0
            }
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
            }
        )

        return TextField("", text: binding)
            .keyboardType(.numberPad)
            .textContentType(index == 0 ? .oneTimeCode : .none)
            .multilineTextAlignment(.center)
            .font(.system(size: 22, weight: .bold))
            .foregroundStyle(AppTheme.Colors.buttonText(scheme))
            .tint(AppTheme.Colors.buttonText(scheme))
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
            .onChange(of: state.otpDigits[index]) { oldValue, newValue in
                let digits = newValue.filter { $0.isNumber }
                // Only drive focus changes when the user is editing this field
                guard focused == field else { return }
                if digits.isEmpty {
                    // User cleared this box -> move back
                    focused = previousField(for: field)
                } else if digits.count > 1 {
                    // Pasted multiple digits -> jump accordingly
                    focused = fieldAfterPastedDigits(from: field, count: digits.count)
                } else {
                    // Single digit entered -> advance
                    focused = nextField(for: field)
                }
            }
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

    private func fieldAfterPastedDigits(from field: Field, count: Int) -> Field? {
        let startIndex: Int
        switch field {
        case .d0: startIndex = 0
        case .d1: startIndex = 1
        case .d2: startIndex = 2
        case .d3: startIndex = 3
        }

        let nextIndex = min(startIndex + count, 4)
        switch nextIndex {
        case 0: return .d0
        case 1: return .d1
        case 2: return .d2
        case 3: return .d3
        default: return nil
        }
    }

    private func otpActionButton(
        title: String,
        enabled: Bool,
        onTap: @escaping () -> Void
    ) -> some View {
        Button(action: onTap) {
            Text(title)
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(
                    AppTheme.Colors.primaryText(scheme).opacity(enabled ? 0.55 : 0.25)
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

