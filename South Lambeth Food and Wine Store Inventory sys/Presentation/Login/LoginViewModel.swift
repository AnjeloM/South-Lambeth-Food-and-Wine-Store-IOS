//
//  SignInViewModel.swift
//  South Lambeth Food and Wine Store Inventory sys
//
//  Created by Mariyan Anjelo on 19/01/2026.
//
import Foundation
import Combine

@MainActor
public final class LoginViewModel: ObservableObject {
    @Published public private(set) var state: LoginUiState

    // One-off events (navigation, alerts)
    private let effectContinuation: AsyncStream<LoginUiEffect>.Continuation
    public let effects: AsyncStream<LoginUiEffect>

    public init(initialState: LoginUiState? = nil) {
        self.state = initialState ?? LoginUiState()

        var cont: AsyncStream<LoginUiEffect>.Continuation!
        self.effects = AsyncStream<LoginUiEffect> { continuation in
            cont = continuation
        }
        self.effectContinuation = cont

        // Make sure state is consistent on init
        recalcDerivedState()
    }

    deinit {
        effectContinuation.finish()
    }

    public func onEvent(_ event: LoginUiEvent) {
        switch event {
        case .onAppear:
            // No business login yet
            break
        case .backTapped:
            emit(.navigateBack)
            
       

        }
    }

    // MARK: - Private
    private func emit(_ effect: LoginUiEffect) {
        effectContinuation.yield(effect)
    }

    private func recalcDerivedState() {
        // Front-end only rule: enable if both are non-empty
        // Later:  replace with proper validation (email format, password rules, etc.)
        let emailOk = !state.email.trimmingCharacters(
            in: .whitespacesAndNewlines
        ).isEmpty
        let passwordOk = !state.password.trimmingCharacters(
            in: .whitespacesAndNewlines
        ).isEmpty
        state.isLoginEnabled = emailOk && passwordOk
    }
}
