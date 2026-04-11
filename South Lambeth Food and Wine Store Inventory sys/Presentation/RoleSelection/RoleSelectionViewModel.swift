import Foundation
import Combine

// MARK: - RoleSelectionViewModel

@MainActor
public final class RoleSelectionViewModel: ObservableObject {

    @Published public private(set) var state: RoleSelectionUiState

    public let effects: AsyncStream<RoleSelectionUiEffect>
    private let effectContinuation: AsyncStream<RoleSelectionUiEffect>.Continuation

    // MARK: - Init

    public init(initialState: RoleSelectionUiState? = nil) {
        self.state = initialState ?? RoleSelectionUiState()

        var cont: AsyncStream<RoleSelectionUiEffect>.Continuation!
        self.effects = AsyncStream(bufferingPolicy: .bufferingNewest(10)) { cont = $0 }
        self.effectContinuation = cont
    }

    deinit { effectContinuation.finish() }

    // MARK: - Event handler

    public func onEvent(_ event: RoleSelectionUiEvent) {
        switch event {
        case .backTapped:
            emit(.navigateBack)
        case .userRoleTapped:
            emit(.navigateToUserSignUp)
        case .ownerRoleTapped:
            emit(.navigateToOwnerSignUp)
        }
    }

    // MARK: - Private

    private func emit(_ effect: RoleSelectionUiEffect) {
        effectContinuation.yield(effect)
    }
}

