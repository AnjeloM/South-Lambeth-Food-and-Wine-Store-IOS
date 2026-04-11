import Foundation
import Combine
import SwiftUI

@MainActor
public final class WelcomeViewModel: ObservableObject {
    @Published public private(set) var state: WelcomeUiState

    private let effectSubject = PassthroughSubject<WelcomeUiEffect, Never>()

    public var effects: AnyPublisher<WelcomeUiEffect, Never> {
        effectSubject.eraseToAnyPublisher()
    }

    public init(initialState: WelcomeUiState = WelcomeUiState()) {
        self.state = initialState
    }

    public func onEvent(_ event: WelcomeUiEvent) {
        switch event {
        case .getStartedTapped:
            emit(.navigateToSignIn)
        }
    }

    private func emit(_ effect: WelcomeUiEffect) {
        effectSubject.send(effect)
    }
}
