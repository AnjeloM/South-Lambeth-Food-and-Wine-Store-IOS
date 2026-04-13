import Foundation
import Combine

// MARK: - SwitchShopViewModel

@MainActor
public final class SwitchShopViewModel: ObservableObject {

    @Published public private(set) var state: SwitchShopUiState
    @Published public private(set) var effect: SwitchShopUiEffect?

    private let shopManager: ShopManaging
    private let requestManager: EmployeeRequestManaging
    private let initialHighlightedRequestID: String?

    // MARK: - Init

    public init(
        initialState: SwitchShopUiState? = nil,
        shopManager: ShopManaging = DemoShopManager(),
        requestManager: EmployeeRequestManaging = DemoEmployeeRequestCenter(),
        initialHighlightedRequestID: String? = nil
    ) {
        self.state = initialState ?? SwitchShopUiState()
        self.shopManager = shopManager
        self.requestManager = requestManager
        self.initialHighlightedRequestID = initialHighlightedRequestID
    }

    deinit {}

    // MARK: - Event Handler

    public func onEvent(_ event: SwitchShopUiEvent) {
        switch event {

        // MARK: Lifecycle
        case .onAppear:
            Task {
                await loadShops()
                await loadEmployeeRequests()
            }

        // MARK: Navigation
        case .closeTapped:
            emit(.close)

        // MARK: Shop row tap
        case .shopTapped(let id):
            guard !state.isSwitching, !state.isLoadingShops else { return }
            guard let shop = state.shops.first(where: { $0.id == id }),
                  !shop.isCurrentShop else { return }
            if state.isOwner {
                Task { await switchShop(to: shop) }
            } else {
                state.pendingSwitchShopId = id
            }

        // MARK: User — switch confirmation
        case .switchConfirmed:
            guard let shop = state.pendingSwitchShop else { return }
            state.pendingSwitchShopId = nil
            Task { await switchShop(to: shop) }

        case .switchCancelled:
            state.pendingSwitchShopId = nil

        // MARK: Owner — shop form
        case .addShopTapped:
            state.editingShopId = nil
            state.draftName = ""
            state.draftAddress = ""
            state.draftPhone = ""
            state.isShopFormPresented = true

        case .editShopTapped(let id):
            guard let shop = state.shops.first(where: { $0.id == id }) else { return }
            state.editingShopId = id
            state.draftName = shop.name
            state.draftAddress = shop.address
            state.draftPhone = shop.phone
            state.isShopFormPresented = true

        case .draftNameChanged(let value):
            state.draftName = value

        case .draftAddressChanged(let value):
            state.draftAddress = value

        case .draftPhoneChanged(let value):
            state.draftPhone = value

        case .saveShopTapped:
            guard state.isFormValid else { return }
            let isEditing = state.editingShopId != nil
            Task { await saveShop(isEditing: isEditing) }

        case .shopFormDismissed:
            state.isShopFormPresented = false
            state.editingShopId = nil
            state.draftName = ""
            state.draftAddress = ""
            state.draftPhone = ""

        // MARK: Owner — delete shop
        case .deleteShopTapped(let id):
            guard state.shops.count > 1 else {
                emit(.showToast("You must have at least one shop."))
                return
            }
            state.deletingShopId = id
            state.deleteConfirmText = ""

        case .deleteConfirmTextChanged(let value):
            state.deleteConfirmText = value

        case .confirmDeleteTapped:
            guard state.isDeleteConfirmValid,
                  let deleteId = state.deletingShopId else { return }
            Task { await deleteShop(id: deleteId) }

        case .deleteSheetDismissed:
            state.deletingShopId = nil
            state.deleteConfirmText = ""

        // MARK: Owner — set global default shop
        case .setDefaultShopTapped(let id):
            guard !state.isSettingDefault else { return }
            guard let shop = state.shops.first(where: { $0.id == id }),
                  !shop.isDefaultShop else { return }
            Task { await setDefaultShop(id: id) }

        // MARK: Owner — employee list expand / collapse
        case .shopExpandTapped(let id):
            if state.expandedShopIds.contains(id) {
                state.expandedShopIds.remove(id)
            } else {
                state.expandedShopIds.insert(id)
                // Lazy load — only fetch once per session
                if state.employeesByShop[id] == nil {
                    Task { await loadEmployees(for: id) }
                }
            }

        // MARK: Owner — employee signup requests
        case .requestsSectionTapped:
            state.isRequestsExpanded.toggle()

        case .requestTapped(let id):
            state.selectedRequestId = id
            state.highlightedRequestId = id

        case .requestSheetDismissed:
            state.selectedRequestId = nil
            state.highlightedRequestId = nil

        case .approveRequestTapped:
            guard let request = state.selectedRequest else { return }
            Task { await approveRequest(request.id) }

        case .rejectRequestTapped:
            guard let request = state.selectedRequest else { return }
            Task { await rejectRequest(request.id) }
        }
    }

    // MARK: - Load Shops

    private func loadShops() async {
        state.isLoadingShops = true
        do {
            let result = try await shopManager.loadShops()
            state.shops = result.entries
            state.isOwner = result.isOwner
        } catch {
            emit(.showToast("Failed to load shops: \(error.localizedDescription)"))
        }
        state.isLoadingShops = false
    }

    // MARK: - Load Employee Requests

    private func loadEmployeeRequests() async {
        guard state.isOwner else {
            state.employeeRequests = []
            state.isRequestsExpanded = false
            return
        }

        state.isLoadingRequests = true
        do {
            state.employeeRequests = try await requestManager.loadPendingRequests()
            if let initialHighlightedRequestID,
               state.employeeRequests.contains(where: { $0.id == initialHighlightedRequestID }) {
                state.highlightedRequestId = initialHighlightedRequestID
                state.isRequestsExpanded = true
            }
        } catch {
            emit(.showToast("Failed to load requests: \(error.localizedDescription)"))
        }
        state.isLoadingRequests = false
    }

    // MARK: - Save Shop (add or edit)

    private func saveShop(isEditing: Bool) async {
        let name    = state.draftName.trimmingCharacters(in: .whitespaces)
        let address = state.draftAddress.trimmingCharacters(in: .whitespaces)
        let phone   = state.draftPhone.trimmingCharacters(in: .whitespaces)

        state.isShopFormPresented = false

        if isEditing, let editId = state.editingShopId {
            do {
                try await shopManager.updateShop(id: editId, name: name, address: address, phone: phone)
                state.shops = state.shops.map { s in
                    guard s.id == editId else { return s }
                    var copy = s
                    copy.name = name; copy.address = address; copy.phone = phone
                    return copy
                }
                emit(.showToast("Shop updated."))
            } catch {
                emit(.showToast("Failed to update shop: \(error.localizedDescription)"))
            }
        } else {
            do {
                let newEntry = try await shopManager.addShop(name: name, address: address, phone: phone)
                // If this is the first shop, mark it as current
                var entry = newEntry
                if state.shops.isEmpty {
                    entry.isCurrentShop = true
                    shopManager.setActiveShop(id: entry.id)
                }
                state.shops.append(entry)
                emit(.showToast("Shop added."))
            } catch {
                emit(.showToast("Failed to add shop: \(error.localizedDescription)"))
            }
        }

        state.editingShopId = nil
        state.draftName = ""
        state.draftAddress = ""
        state.draftPhone = ""
    }

    // MARK: - Switch Shop

    private func switchShop(to shop: SwitchShopEntry) async {
        state.isSwitching = true
        do {
            try await shopManager.setCurrentShop(id: shop.id)
            state.shops = state.shops.map { s in
                var copy = s
                copy.isCurrentShop = (s.id == shop.id)
                return copy
            }
            emit(.showToast("Switched to \(shop.name)"))
        } catch {
            emit(.showToast("Failed to switch shop: \(error.localizedDescription)"))
        }
        state.isSwitching = false
    }

    // MARK: - Delete Shop

    private func deleteShop(id: String) async {
        state.isDeletingShop = true
        let wasCurrentShop = state.shops.first(where: { $0.id == id })?.isCurrentShop ?? false

        do {
            try await shopManager.removeShop(id: id)
            state.shops.removeAll(where: { $0.id == id })

            // Auto-promote first remaining shop as active and persist to Firestore
            if wasCurrentShop, !state.shops.isEmpty {
                state.shops[0].isCurrentShop = true
                try await shopManager.setCurrentShop(id: state.shops[0].id)
            }
            emit(.showToast("Shop removed."))
        } catch {
            emit(.showToast("Failed to remove shop: \(error.localizedDescription)"))
        }

        state.isDeletingShop = false
        state.deletingShopId = nil
        state.deleteConfirmText = ""
    }

    // MARK: - Load Employees

    private func loadEmployees(for shopId: String) async {
        state.loadingEmployeesForShop.insert(shopId)
        do {
            let employees = try await shopManager.loadEmployees(for: shopId)
            state.employeesByShop[shopId] = employees
        } catch {
            emit(.showToast("Failed to load employees: \(error.localizedDescription)"))
        }
        state.loadingEmployeesForShop.remove(shopId)
    }

    // MARK: - Set Default Shop

    private func setDefaultShop(id: String) async {
        state.isSettingDefault = true
        do {
            try await shopManager.setDefaultShop(id: id)
            // Sync both the global default and the owner's current working shop in Firestore
            try await shopManager.setCurrentShop(id: id)
            state.shops = state.shops.map { s in
                var copy = s
                copy.isDefaultShop = (s.id == id)
                copy.isCurrentShop = (s.id == id)
                return copy
            }
            emit(.showToast("Active shop updated for all users."))
        } catch {
            emit(.showToast("Failed to update active shop: \(error.localizedDescription)"))
        }
        state.isSettingDefault = false
    }

    // MARK: - Request Actions

    private func approveRequest(_ id: String) async {
        state.isUpdatingRequest = true
        let approvedShopID = state.selectedRequest?.shopID
        do {
            try await requestManager.approveRequest(id: id)
            await loadEmployeeRequests()
            if let approvedShopID, approvedShopID == state.currentShop?.id {
                await loadEmployees(for: approvedShopID)
            }
            state.selectedRequestId = nil
            state.highlightedRequestId = nil
            emit(.showToast("Employee approved."))
        } catch {
            emit(.showToast("Failed to approve request: \(error.localizedDescription)"))
        }
        state.isUpdatingRequest = false
    }

    private func rejectRequest(_ id: String) async {
        state.isUpdatingRequest = true
        do {
            try await requestManager.rejectRequest(id: id)
            await loadEmployeeRequests()
            state.selectedRequestId = nil
            state.highlightedRequestId = nil
            emit(.showToast("Request rejected."))
        } catch {
            emit(.showToast("Failed to reject request: \(error.localizedDescription)"))
        }
        state.isUpdatingRequest = false
    }

    // MARK: - Effect Emitter

    private func emit(_ newEffect: SwitchShopUiEffect) {
        effect = newEffect
        Task { @MainActor in
            await Task.yield()
            self.effect = nil
        }
    }
}
