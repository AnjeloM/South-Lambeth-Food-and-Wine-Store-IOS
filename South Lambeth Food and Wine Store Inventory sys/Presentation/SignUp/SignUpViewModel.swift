import Combine
import Foundation

@MainActor
public final class SignUpViewModel: ObservableObject {
    @Published public private(set) var state: SignUpUiState

    public let effects: AsyncStream<SignUpUiEffect>
    private let effectContinuation: AsyncStream<SignUpUiEffect>.Continuation

    private let otpSender: SignUpOtpSending

    // MARK: - Init

    public init(
        initialState: SignUpUiState? = nil,
        otpSender: SignUpOtpSending = DemoSignUpOtpSender()
    ) {
        self.state = initialState ?? SignUpUiState()
        self.otpSender = otpSender

        var cont: AsyncStream<SignUpUiEffect>.Continuation!
        self.effects = AsyncStream(bufferingPolicy: .bufferingNewest(10)) { cont = $0 }
        self.effectContinuation = cont
    }

    deinit { effectContinuation.finish() }

    // MARK: - Events

    public func onEvent(_ event: SignUpUiEvent) {
        switch event {
        case .onAppear:
            break

        case .onbackTapped:
            emit(.navigateBack)

        case .nameChanged(let value):
            state.name = value

        case .emailChanged(let value):
            state.email = value
            state.emailError = nil

        case .passwordChanged(let value):
            state.password = value

        case .retypePasswordChanged(let value):
            state.retypePassword = value

        case .togglePasswordVisibility:
            state.isPasswordVisible.toggle()

        case .toggleRetypePasswordVisibility:
            state.isRetypePasswordVisible.toggle()

        case .googleTapped:
            emit(.continueWithGoogle)

        case .appleTapped:
            emit(.continueWithApple)

        case .privacyPolicyTapped:
            emit(.openURL(URL(string: "https://example.com/privacy")!))

        case .termsTapped:
            emit(.openURL(URL(string: "https://example.com/terms")!))

        case .signUpTapped:
            Task { await signUp() }
        }
    }

    // MARK: - Sign Up

    private func signUp() async {
        guard !state.isLoading else { return }

        let name     = state.name.trimmingCharacters(in: .whitespaces)
        let email    = state.email.trimmingCharacters(in: .whitespaces).lowercased()
        let password = state.password
        let retype   = state.retypePassword

        // — Basic field validation —
        guard !name.isEmpty else {
            emit(.showToast("Please enter your name."))
            return
        }
        guard !email.isEmpty else {
            emit(.showToast("Please enter your email address."))
            return
        }

        guard !password.isEmpty else {
            emit(.showToast("Please enter a password."))
            return
        }
        guard isStrongPassword(password) else {
            emit(.showToast("Password must be 8+ characters with 2 uppercase, 2 lowercase, 1 number, and 1 special character."))
            return
        }
        guard password == retype else {
            emit(.showToast("Passwords do not match."))
            return
        }

        // — Send OTP —
        state.isLoading = true
        do {
            try await otpSender.sendOtp(to: email)
            state.isLoading = false
            emit(.navigateToOtp(email: email, name: name, password: password))
        } catch {
            state.isLoading = false
            emit(.showToast("Failed to send verification code: \(error.localizedDescription)"))
        }
    }

    // MARK: - Helpers

    /// Mirrors the password strength rules shown in the UI and enforced server-side.
    private func isStrongPassword(_ pw: String) -> Bool {
        guard pw.count >= 8 else { return false }
        var lower = 0, upper = 0, digit = 0, special = 0
        for ch in pw {
            if ch.isLowercase          { lower   += 1 }
            else if ch.isUppercase     { upper   += 1 }
            else if ch.isNumber        { digit   += 1 }
            else                       { special += 1 }
        }
        return lower >= 2 && upper >= 2 && digit >= 1 && special >= 1
    }

    private func emit(_ effect: SignUpUiEffect) {
        effectContinuation.yield(effect)
    }
}
