import FirebaseAuth

// MARK: - Protocol

public protocol LoginAuthenticating {
    /// Signs in with email and password. Throws on invalid credentials or network error.
    func signIn(email: String, password: String) async throws
}

// MARK: - Firebase implementation

public struct FirebaseLoginAuthenticator: LoginAuthenticating {
    public init() {}

    public func signIn(email: String, password: String) async throws {
        try await Auth.auth().signIn(withEmail: email, password: password)
    }
}

// MARK: - Demo stub (previews / tests only)

public struct DemoLoginAuthenticator: LoginAuthenticating {
    public init() {}

    public func signIn(email: String, password: String) async throws {
        try await Task.sleep(nanoseconds: 500_000_000)
        // Always succeeds — for previews only
    }
}
