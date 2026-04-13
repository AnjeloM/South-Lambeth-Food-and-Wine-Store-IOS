import Foundation
import Combine

// MARK: - JoinShopViewModel

@MainActor
public final class JoinShopViewModel: ObservableObject {

    @Published public private(set) var state: JoinShopUiState
    @Published public private(set) var effect: JoinShopUiEffect?

    // MARK: Dependencies

    private let ownerFetcher: OwnerFetching
    private let requestSubmitter: ShopRequestSubmitting
    private let sessionManager: SessionManaging

    /// Cancellable search task — replaced on every keystroke to implement debounce.
    private var searchTask: Task<Void, Never>?

    // MARK: Init

    public init(
        ownerFetcher: OwnerFetching = FirebaseOwnerFetcher(),
        requestSubmitter: ShopRequestSubmitting = FirebaseShopRequestSubmitter(),
        sessionManager: SessionManaging = LocalSessionManager()
    ) {
        self.state = JoinShopUiState()
        self.ownerFetcher = ownerFetcher
        self.requestSubmitter = requestSubmitter
        self.sessionManager = sessionManager
    }

    // MARK: - Event Handler

    public func onEvent(_ event: JoinShopUiEvent) {
        switch event {

        case .onAppear:
            Task { await checkPendingRequest() }

        case .ownerPickerTapped:
            guard !state.isBlocking else { return }
            state.isOwnerPickerPresented = true

        case .ownerSearchChanged(let text):
            state.ownerSearchText = text
            scheduleOwnerSearch(query: text)

        case .ownerPickerDismissed:
            searchTask?.cancel()
            state.ownerSearchText = ""
            state.ownerSearchResults = []
            state.ownerSearchIsEmpty = false
            state.isSearchingOwners = false
            state.isOwnerPickerPresented = false

        case .shopSelected(let shop, let owner):
            state.selectedShop = shop
            state.selectedOwner = owner
            state.isOwnerPickerPresented = false
            // Reset search state so the sheet opens clean next time.
            state.ownerSearchText = ""
            state.ownerSearchResults = []
            state.ownerSearchIsEmpty = false
            state.isSearchingOwners = false

        case .submitTapped:
            guard state.isFormValid, !state.isSubmitting else { return }
            Task { await submitRequest() }

        case .logoutTapped:
            sessionManager.clearSession()
            emit(.navigateWelcome)
        }
    }

    // MARK: - Debounced Search

    private func scheduleOwnerSearch(query: String) {
        searchTask?.cancel()
        state.ownerSearchIsEmpty = false

        guard query.count >= 2 else {
            state.ownerSearchResults = []
            state.isSearchingOwners = false
            return
        }

        state.isSearchingOwners = true

        searchTask = Task {
            // 350 ms debounce — lets the user finish a word before hitting Firestore
            try? await Task.sleep(nanoseconds: 350_000_000)
            guard !Task.isCancelled else { return }
            await performOwnerSearch(query: query)
        }
    }

    private func performOwnerSearch(query: String) async {
        do {
            let results = try await ownerFetcher.searchOwners(query: query, limit: 20)
            guard !Task.isCancelled else { return }
            state.ownerSearchResults = results
            state.ownerSearchIsEmpty = results.isEmpty
        } catch {
            guard !Task.isCancelled else { return }
            state.ownerSearchResults = []
            state.ownerSearchIsEmpty = false
        }
        state.isSearchingOwners = false
    }

    // MARK: - Pending Request Check

    private func checkPendingRequest() async {
        state.isCheckingPending = true
        do {
            state.pendingRequest = try await requestSubmitter.pendingRequest()
        } catch {
            // Non-critical — show the selection form anyway
        }
        state.isCheckingPending = false
    }

    // MARK: - Submit Request

    private func submitRequest() async {
        guard let shop = state.selectedShop else { return }
        state.isSubmitting = true
        do {
            try await requestSubmitter.submitJoinRequest(shopID: shop.id)
            state.requestSent = true
        } catch {
            emit(.showToast("Failed to send request. Please try again."))
        }
        state.isSubmitting = false
    }

    // MARK: - Effect

    private func emit(_ newEffect: JoinShopUiEffect) {
        effect = newEffect
        Task { @MainActor in
            await Task.yield()
            self.effect = nil
        }
    }
}
