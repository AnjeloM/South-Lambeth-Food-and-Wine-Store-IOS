import Combine
import Foundation

@MainActor
public final class SendResetMailViewModel: ObservableObject {
    @Published public private(set) var state: SendResetMailUiState

    public let effect: AsyncStream<SendResetMailUiEffect>
    private let effectContinuation: AsyncStream<SendResetMailUiEffect>.Continuation

    private let sender: PasswordResetSending
    private var cooldownTask: Task<Void, Never>?

    // Cooldown steps: 60s, 2m, 5m, 30m, 1h
    private let cooldownPresets: [Int] = [60, 120, 300, 1800, 3600]

    public init(
        initialState: SendResetMailUiState? = nil,
        sender: PasswordResetSending = DemoPasswordResetSender()
    ) {
        self.state = initialState ?? SendResetMailUiState()
        self.sender = sender

        var cont: AsyncStream<SendResetMailUiEffect>.Continuation!
        self.effect = AsyncStream(bufferingPolicy: .bufferingNewest(10)) { cont = $0 }
        self.effectContinuation = cont

        recalcDerivedState()
    }

    deinit {
        cooldownTask?.cancel()
        effectContinuation.finish()
    }

    // MARK: - Events

    public func send(_ event: SendResetMailUiEvent) {
        switch event {
        case .onAppear:
            recalcDerivedState()

        case .onbackTapped:
            emit(.navigateBack)

        case .emailChanged(let value):
            state.email = value
            recalcDerivedState()

        case .resendTapped:
            guard state.isResendEnabled else { return }
            Task { await sendResetLink() }

        case ._tick:
            tickCooldown()
        }
    }

    // MARK: - Send Reset Link

    private func sendResetLink() async {
        let email = state.email.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard isValidEmail(email) else { return }

        state.isSubmitting = true
        recalcDerivedState()

        do {
            try await sender.sendResetLink(to: email)
        } catch {
            // Swallow error intentionally — backend always returns neutral response.
            // A network failure is the only real error; surface it quietly.
            emit(.showToast(message: "Network error. Please try again."))
        }

        state.isSubmitting = false

        // Always start cooldown and show neutral confirmation regardless of backend result
        let seconds = cooldownPresets[min(state.cooldownLevelIndex, cooldownPresets.count - 1)]
        startCooldown(seconds: seconds)
        state.cooldownLevelIndex = min(state.cooldownLevelIndex + 1, cooldownPresets.count - 1)
        recalcDerivedState()

        emit(.showToast(message: "If an account exists for this email, a reset link has been sent."))
    }

    // MARK: - Cooldown

    private func startCooldown(seconds: Int) {
        cooldownTask?.cancel()
        state.cooldownSecondsRemaining = seconds
        state.cooldownText = formatCooldown(seconds)
        recalcDerivedState()

        cooldownTask = Task { [weak self] in
            guard let self else { return }
            while !Task.isCancelled {
                try? await Task.sleep(nanoseconds: 1_000_000_000)
                if Task.isCancelled { break }
                self.send(._tick)
            }
        }
    }

    private func tickCooldown() {
        guard let remaining = state.cooldownSecondsRemaining else { return }
        let next = remaining - 1
        if next <= 0 {
            state.cooldownSecondsRemaining = nil
            state.cooldownText = nil
            cooldownTask?.cancel()
            cooldownTask = nil
        } else {
            state.cooldownSecondsRemaining = next
            state.cooldownText = formatCooldown(next)
        }
        recalcDerivedState()
    }

    // MARK: - Helpers

    private func recalcDerivedState() {
        let emailOk = isValidEmail(state.email)
        let isCooling = (state.cooldownSecondsRemaining ?? 0) > 0
        state.isResendEnabled = emailOk && !state.isSubmitting && !isCooling
    }

    private func isValidEmail(_ raw: String) -> Bool {
        let email = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        return email.count > 5 && email.contains("@") && email.contains(".")
    }

    private func formatCooldown(_ seconds: Int) -> String {
        if seconds >= 3600 {
            return String(format: "%02d:%02d:%02d", seconds / 3600, (seconds % 3600) / 60, seconds % 60)
        }
        return String(format: "%02d:%02d", seconds / 60, seconds % 60)
    }

    private func emit(_ effect: SendResetMailUiEffect) {
        effectContinuation.yield(effect)
    }
}
