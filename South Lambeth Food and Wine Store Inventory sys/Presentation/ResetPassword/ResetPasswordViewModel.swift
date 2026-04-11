import Foundation
import Combine

@MainActor
public final class ResetPasswordViewModel: ObservableObject {
    @Published public private(set) var state: ResetPasswordUiState

    public let effects: AsyncStream<ResetPasswordUiEffect>
    private let effectContinuation: AsyncStream<ResetPasswordUiEffect>.Continuation

    private let resetter: PasswordResetting

    public init(
        token: String,
        resetter: PasswordResetting = DemoPasswordResetter()
    ) {
        self.state = ResetPasswordUiState(token: token)
        self.resetter = resetter

        var cont: AsyncStream<ResetPasswordUiEffect>.Continuation!
        self.effects = AsyncStream(bufferingPolicy: .bufferingNewest(10)) { cont = $0 }
        self.effectContinuation = cont
    }

    deinit { effectContinuation.finish() }

    // MARK: - Events

    public func send(_ event: ResetPasswordUiEvent) {
        switch event {
        case .onAppear:
            break

        case .newPasswordChanged(let value):
            state.newPassword = value
            state.errorMessage = nil
            recalcDerived()

        case .confirmPasswordChanged(let value):
            state.confirmPassword = value
            state.errorMessage = nil
            recalcDerived()

        case .toggleNewPasswordVisibility:
            state.isPasswordVisible.toggle()

        case .toggleConfirmPasswordVisibility:
            state.isConfirmPasswordVisible.toggle()

        case .submitTapped:
            Task { await submit() }
        }
    }

    // MARK: - Submit

    private func submit() async {
        guard state.isSubmitEnabled else { return }

        let password = state.newPassword
        let confirm  = state.confirmPassword

        guard password == confirm else {
            state.errorMessage = "Passwords do not match."
            return
        }

        guard isStrongPassword(password) else {
            state.errorMessage = "Password must be 8+ characters with 2 uppercase, 2 lowercase, 1 number, and 1 special character."
            return
        }

        state.isLoading = true
        recalcDerived()

        do {
            try await resetter.resetPassword(token: state.token, newPassword: password)
            state.isLoading = false
            recalcDerived()
            emit(.showToast("Password reset successful. Please log in."))
            emit(.navigateToLogin)
        } catch {
            state.isLoading = false
            state.errorMessage = error.localizedDescription
            recalcDerived()
        }
    }

    // MARK: - Helpers

    private func recalcDerived() {
        var s = state
        let bothFilled = !s.newPassword.isEmpty && !s.confirmPassword.isEmpty
        s.isSubmitEnabled = bothFilled && !s.isLoading
        state = s
    }

    private func isStrongPassword(_ pw: String) -> Bool {
        guard pw.count >= 8 else { return false }
        var lower = 0, upper = 0, digit = 0, special = 0
        for ch in pw {
            if ch.isLowercase        { lower   += 1 }
            else if ch.isUppercase   { upper   += 1 }
            else if ch.isNumber      { digit   += 1 }
            else                     { special += 1 }
        }
        return lower >= 2 && upper >= 2 && digit >= 1 && special >= 1
    }

    private func emit(_ effect: ResetPasswordUiEffect) {
        effectContinuation.yield(effect)
    }
}

