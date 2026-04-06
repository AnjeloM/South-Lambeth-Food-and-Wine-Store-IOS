import Combine
import Foundation

@MainActor
public final class SendResetMailViewModel: ObservableObject {
    @Published public private(set) var state: SendResetMailUiState

    public let effect: AsyncStream<SendResetMailUiEffect>
    private let effectContinuation:
        AsyncStream<SendResetMailUiEffect>.Continuation

    private var cooldownTask: Task<Void, Never>?

    // Cooldown steps: 60s, 2m, 5m, 30, 1h
    private let cooldownPresets: [Int] = [60, 120, 300, 1800, 3600]

    public init(
        initialState: SendResetMailUiState? = nil
    ) {
        self.state = initialState ?? SendResetMailUiState()

        var cont: AsyncStream<SendResetMailUiEffect>.Continuation!
        self.effect = AsyncStream(bufferingPolicy: .bufferingNewest(10)) {
            continuation in
            cont = continuation
        }
        self.effectContinuation = cont

        recalcDerivedState()
    }

    deinit {
        cooldownTask?.cancel()
        effectContinuation.finish()
    }

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
            // Front-end only: effect for now
            guard state.isResendEnabled else { return }
            emit(
                .showToast(
                    message: "Reset email requested. (Wire Firebase later)"
                )
            )

            // Use current level for this cooldown
            let seconds = cooldownPresets[
                min(state.cooldownLevelIndex, cooldownPresets.count - 1)
            ]
            startOrResetCooldown(seconds: seconds)

            // Prepare next level (caps at last)
            state.cooldownLevelIndex = min(
                state.cooldownLevelIndex + 1,
                cooldownPresets.count - 1
            )

            recalcDerivedState()

        case ._tick:
            tickCooldown()
        }
    }

    private func emit(_ effect: SendResetMailUiEffect) {
        effectContinuation.yield(effect)
    }

    private func recalcDerivedState() {
        let isEmailValid = isValidEmail(state.email)
        let isCoolingDown = (state.cooldownSecondsRemaining ?? 0) > 0

        state.isResendEnabled =
            isEmailValid
            && !state.isSubmitting
            && !isCoolingDown
    }

    private func isValidEmail(_ raw: String) -> Bool {
        let email = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        guard email.count > 5 else { return false }
        // Lightweight check for UI enabling only (replace with stricter logic if you want)
        return email.contains("@") && email.contains(".")
    }

    // MARK: Cooldown
    private func startOrResetCooldown(seconds: Int) {
        cooldownTask?.cancel()

        state.cooldownSecondsRemaining = seconds
        state.cooldownText = formatCoolDown(seconds)

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

            recalcDerivedState()
        } else {
            state.cooldownSecondsRemaining = next
            state.cooldownText = formatCoolDown(next)
        }
    }

    private func formatCoolDown(_ seconds: Int) -> String {
        if seconds >= 3600 {
            let h = seconds / 3600
            let m = (seconds % 3600) / 60
            let s = seconds % 60
            return String(format: "%02d:%02d:%02d", h, m, s)
        } else {
            let m = seconds / 60
            let s = seconds % 60
            return String(format: "%02d:%02d", m, s)
        }
    }
}
