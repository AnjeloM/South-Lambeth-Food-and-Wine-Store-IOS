import Foundation
import Combine

@MainActor
public final class EmailOtpVerificationViewModel: ObservableObject {
    @Published public private(set) var state: EmailOtpVerificationUiState

    public let effects: AsyncStream<EmailOtpVerificationEffect>
    private let effectContinuation: AsyncStream<EmailOtpVerificationEffect>.Continuation

    private let service: EmailOtpServicing
    private var cooldownTask: Task<Void, Never>?

    // Cooldown steps: 60s, 2m, 5m, 30m, 1h
    private let cooldownPresets: [Int] = [60, 120, 300, 1800, 3600]

    public init(
        email: String,
        service: EmailOtpServicing,
        initialState: EmailOtpVerificationUiState? = nil
    ) {
        self.service = service
        self.state = initialState ?? EmailOtpVerificationUiState(email: email)

        var cont: AsyncStream<EmailOtpVerificationEffect>.Continuation!
        self.effects = AsyncStream(bufferingPolicy: .bufferingNewest(10)) { continuation in
            cont = continuation
        }
        self.effectContinuation = cont

        // Assumption: OTP was sent from SignUp → start initial cooldown now.
        startCooldown(seconds: cooldownPresets[0])
        recalcDerived()
    }

    deinit {
        cooldownTask?.cancel()
        effectContinuation.finish()
    }

    public func send(_ event: EmailOtpVerificationUiEvent) {
        switch event {
        case .onAppear:
            break

        case .backTapped:
            emit(.navigateBack)

        case let .otpChanged(index, value):
            applyOtpInput(index: index, raw: value)
            recalcDerived()

        case .verifyTapped:
            verify()

        case .resendTapped:
            resend()
        }
    }

    // MARK: - OTP Input

    private func applyOtpInput(index: Int, raw: String) {
        guard (0..<4).contains(index) else { return }

        // digits only
        let digitsOnly = raw.filter { $0.isNumber }

        if digitsOnly.isEmpty {
            state.otpDigits[index] = ""
            return
        }

        // paste support: spread multiple digits starting at index
        if digitsOnly.count > 1 {
            var i = index
            for ch in digitsOnly {
                guard i < 4 else { break }
                state.otpDigits[i] = String(ch)
                i += 1
            }
            return
        }

        // single digit
        state.otpDigits[index] = String(digitsOnly.prefix(1))
    }

    // MARK: - Verify

    private func verify() {
        recalcDerived()
        guard state.verifyEnabled else { return }

        let otp = state.otpDigits.joined()
        state.isVerifying = true
        recalcDerived()

        Task {
            do {
                try await service.verifyOtp(email: state.email, otp: otp)
                state.isVerifying = false
                recalcDerived()
                emit(.verifiedSuccessfully)
            } catch {
                state.isVerifying = false
                recalcDerived()
                emit(.showToast(error.localizedDescription))
            }
        }
    }

    // MARK: - Resend + Escalating Cooldown

    private func resend() {
        guard state.canResend, !state.isVerifying else { return }

        Task {
            do {
                try await service.resendOtp(email: state.email)

                // next step (clamped)
                state.resendStepIndex = min(state.resendStepIndex + 1, cooldownPresets.count - 1)

                // start new cooldown
                startCooldown(seconds: cooldownPresets[state.resendStepIndex])

                emit(.showToast("OTP resent. Please check your email."))
            } catch {
                emit(.showToast(error.localizedDescription))
            }
        }
    }

    private func startCooldown(seconds: Int) {
        cooldownTask?.cancel()

        state.canResend = false
        state.resendRemainingSeconds = max(0, seconds)
        recalcDerived()

        cooldownTask = Task { [weak self] in
            guard let self else { return }

            while !Task.isCancelled && self.state.resendRemainingSeconds > 0 {
                try? await Task.sleep(nanoseconds: 1_000_000_000)
                if Task.isCancelled { return }
                self.state.resendRemainingSeconds -= 1
                self.recalcDerived()
            }

            if !Task.isCancelled {
                self.state.resendRemainingSeconds = 0
                self.state.canResend = true
                self.recalcDerived()
            }
        }
    }

    // MARK: - Derived

    private func recalcDerived() {
        let complete = state.otpDigits.allSatisfy { $0.count == 1 }
        state.isOtpComplete = complete
        state.verifyEnabled = complete && !state.isVerifying
        state.resendLabel = "Resend in: \(format(seconds: state.resendRemainingSeconds))"
        if state.resendRemainingSeconds == 0 { state.canResend = true }
    }

    private func format(seconds: Int) -> String {
        let m = seconds / 60
        let s = seconds % 60
        return String(format: "%02d:%02ds", m, s)
    }

    private func emit(_ effect: EmailOtpVerificationEffect) {
        effectContinuation.yield(effect)
    }
}
