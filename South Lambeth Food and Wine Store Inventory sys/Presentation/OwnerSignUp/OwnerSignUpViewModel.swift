import Foundation
import Combine

// MARK: - OwnerSignUpViewModel

@MainActor
public final class OwnerSignUpViewModel: ObservableObject {

    @Published public private(set) var state: OwnerSignUpUiState

    public let effects: AsyncStream<OwnerSignUpUiEffect>
    private let effectContinuation: AsyncStream<OwnerSignUpUiEffect>.Continuation

    // MARK: - Init

    public init(initialState: OwnerSignUpUiState? = nil) {
        self.state = initialState ?? OwnerSignUpUiState()

        var cont: AsyncStream<OwnerSignUpUiEffect>.Continuation!
        self.effects = AsyncStream(bufferingPolicy: .bufferingNewest(10)) { cont = $0 }
        self.effectContinuation = cont
    }

    deinit { effectContinuation.finish() }

    // MARK: - Event handler

    public func onEvent(_ event: OwnerSignUpUiEvent) {
        switch event {

        // MARK: Navigation
        case .backTapped:
            emit(.navigateBack)

        // MARK: Account details
        case .nameChanged(let v):
            state.name = v
            state.nameError = nil

        case .emailChanged(let v):
            state.email = v
            state.emailError = nil

        case .passwordChanged(let v):
            state.password = v

        case .retypePasswordChanged(let v):
            state.retypePassword = v

        case .togglePasswordVisible:
            state.isPasswordVisible.toggle()

        case .toggleRetypePasswordVisible:
            state.isRetypePasswordVisible.toggle()

        // MARK: Shop list actions

        case .addShopTapped:
            state.draftShop = OwnerShopEntry()
            state.editingShopId = nil
            state.draftShopNameError = nil
            state.draftShopAddressError = nil
            state.isShopSheetPresented = true

        case .editShopTapped(let id):
            guard let shop = state.shops.first(where: { $0.id == id }) else { return }
            state.draftShop = shop
            state.editingShopId = id
            state.draftShopNameError = nil
            state.draftShopAddressError = nil
            state.isShopSheetPresented = true

        case .deleteShopTapped(let id):
            state.shopPendingDeleteId = id
            state.deleteConfirmText = ""
            state.isDeleteConfirmPresented = true

        // MARK: Shop add/edit sheet

        case .draftShopNameChanged(let v):
            state.draftShop.name = v
            state.draftShopNameError = nil

        case .draftShopAddressChanged(let v):
            state.draftShop.address = v
            state.draftShopAddressError = nil

        case .draftShopPhoneChanged(let v):
            state.draftShop.phone = applyPhoneMask(v)

        case .draftShopLocationTapped:
            // MARK: Firebase – pending (Google Maps picker)
            // Will present the Maps picker and populate locationLabel + lat/lng.
            emit(.showToast("Location picker coming soon"))

        case .saveShopTapped:
            saveShop()

        case .cancelShopSheetTapped:
            state.isShopSheetPresented = false

        // MARK: Delete confirmation

        case .deleteConfirmTextChanged(let v):
            state.deleteConfirmText = v

        case .confirmDeleteTapped:
            guard state.isDeleteConfirmValid, let id = state.shopPendingDeleteId else { return }
            state.shops.removeAll { $0.id == id }
            state.isDeleteConfirmPresented = false
            state.shopPendingDeleteId = nil
            state.deleteConfirmText = ""

        case .cancelDeleteTapped:
            state.isDeleteConfirmPresented = false
            state.shopPendingDeleteId = nil
            state.deleteConfirmText = ""

        // MARK: Submit
        case .signUpTapped:
            Task { await submit() }
        }
    }

    // MARK: - Save shop (add or update)

    private func saveShop() {
        var hasError = false

        let name    = state.draftShop.name.trimmingCharacters(in: .whitespaces)
        let address = state.draftShop.address.trimmingCharacters(in: .whitespaces)

        if name.isEmpty {
            state.draftShopNameError = "Shop name is required"
            hasError = true
        }
        if address.isEmpty {
            state.draftShopAddressError = "Shop address is required"
            hasError = true
        }
        guard !hasError else { return }

        state.draftShop.name    = name
        state.draftShop.address = address

        if let editId = state.editingShopId,
           let idx = state.shops.firstIndex(where: { $0.id == editId }) {
            state.shops[idx] = state.draftShop
        } else {
            state.shops.append(state.draftShop)
        }

        state.isShopSheetPresented = false
    }

    // MARK: - Submit (frontend stub)

    private func submit() async {
        let name  = state.name.trimmingCharacters(in: .whitespaces)
        let email = state.email.trimmingCharacters(in: .whitespaces).lowercased()

        var hasError = false
        if name.isEmpty {
            state.nameError = "Name is required"
            hasError = true
        }
        if email.isEmpty {
            state.emailError = "Email is required"
            hasError = true
        } else if !isValidEmail(email) {
            state.emailError = "Enter a valid email address"
            hasError = true
        }
        guard !hasError else { return }

        guard !state.password.isEmpty else {
            emit(.showToast("Please enter a password."))
            return
        }
        guard isStrongPassword(state.password) else {
            emit(.showToast("Password must be 8+ characters with 2 uppercase, 2 lowercase, 1 number, and 1 special character."))
            return
        }
        guard state.password == state.retypePassword else {
            emit(.showToast("Passwords do not match."))
            return
        }
        guard !state.shops.isEmpty else {
            emit(.showToast("Please add at least one shop before signing up."))
            return
        }

        // MARK: Firebase – pending
        // Replace with OTP send + registration flow once backend is wired.
        emit(.showToast("Owner registration coming soon — backend integration pending."))
    }

    // MARK: - Helpers

    /// UK-style phone mask: strips non-digits, caps at 11, formats as "XXXXX XXXXXX".
    private func applyPhoneMask(_ raw: String) -> String {
        let digits = raw.filter(\.isNumber)
        let capped = String(digits.prefix(11))
        guard capped.count > 5 else { return capped }
        let first = String(capped.prefix(5))
        let rest  = String(capped.dropFirst(5))
        return "\(first) \(rest)"
    }

    private func isValidEmail(_ email: String) -> Bool {
        email.contains("@") && email.contains(".")
    }

    private func isStrongPassword(_ pw: String) -> Bool {
        guard pw.count >= 8 else { return false }
        var lower = 0, upper = 0, digit = 0, special = 0
        for ch in pw {
            if ch.isLowercase      { lower   += 1 }
            else if ch.isUppercase { upper   += 1 }
            else if ch.isNumber    { digit   += 1 }
            else                   { special += 1 }
        }
        return lower >= 2 && upper >= 2 && digit >= 1 && special >= 1
    }

    private func emit(_ effect: OwnerSignUpUiEffect) {
        effectContinuation.yield(effect)
    }
}

