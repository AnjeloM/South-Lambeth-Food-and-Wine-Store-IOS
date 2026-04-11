import SwiftUI

// MARK: - OwnerSignUpScreen
//
// Pure view — renders OwnerSignUpUiState, emits OwnerSignUpUiEvent.
// Zero business logic, zero ViewModel reference.

public struct OwnerSignUpScreen: View {

    public let state: OwnerSignUpUiState
    public let onEvent: (OwnerSignUpUiEvent) -> Void

    public init(
        state: OwnerSignUpUiState,
        onEvent: @escaping (OwnerSignUpUiEvent) -> Void
    ) {
        self.state = state
        self.onEvent = onEvent
    }

    @Environment(\.colorScheme) private var scheme

    private enum Field: Hashable {
        case name, email, password, retypePassword
    }
    @FocusState private var focus: Field?

    // MARK: - Body

    public var body: some View {
        ZStack {
            AppTheme.Colors.background(scheme).ignoresSafeArea()

            VStack(spacing: 0) {
                AppTopBar(
                    title: "Owner Sign Up",
                    showBack: true,
                    showsShadow: true
                ) {
                    onEvent(.backTapped)
                }

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 24) {

                        // MARK: Account Details
                        sectionHeader(icon: "person.crop.circle.fill", title: "Account Details")
                        accountDetailsSection

                        divider

                        // MARK: Shops
                        sectionHeader(icon: "storefront.fill", title: "Your Shops")
                        shopsSection

                        divider

                        // MARK: Submit
                        AppPillButton(
                            title: "Sign Up as Owner",
                            isLoading: state.isLoading,
                            isEnabled: !state.isLoading
                        ) {
                            onEvent(.signUpTapped)
                        }
                        .padding(.top, 4)
                    }
                    .padding(.horizontal, AppTheme.Layout.screenHPadding)
                    .padding(.top, 20)
                    .padding(.bottom, 32)
                }
                .scrollDismissesKeyboard(.interactively)
                .simultaneousGesture(TapGesture().onEnded { focus = nil })
                .toolbar {
                    ToolbarItemGroup(placement: .keyboard) {
                        Spacer()
                        Button("Done") { focus = nil }
                    }
                }
            }
        }
        // MARK: Shop add/edit sheet
        .sheet(isPresented: shopSheetBinding) {
            ShopFormSheet(
                state: state,
                onEvent: onEvent
            )
            .presentationDetents([.large])
            .presentationDragIndicator(.hidden)
        }
        // MARK: Delete confirmation sheet
        .sheet(isPresented: deleteSheetBinding) {
            DeleteConfirmSheet(
                state: state,
                onEvent: onEvent
            )
            .presentationDetents([.medium])
            .presentationDragIndicator(.hidden)
        }
    }

    // MARK: - Sheet bindings (read-only; dismissal is handled via events)

    private var shopSheetBinding: Binding<Bool> {
        Binding(
            get: { state.isShopSheetPresented },
            set: { if !$0 { onEvent(.cancelShopSheetTapped) } }
        )
    }

    private var deleteSheetBinding: Binding<Bool> {
        Binding(
            get: { state.isDeleteConfirmPresented },
            set: { if !$0 { onEvent(.cancelDeleteTapped) } }
        )
    }

    // MARK: - Section header

    @ViewBuilder
    private func sectionHeader(icon: String, title: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(AppTheme.Colors.accent(scheme))
            Text(title)
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(AppTheme.Colors.primaryText(scheme))
            Spacer()
        }
    }

    private var divider: some View {
        Rectangle()
            .fill(AppTheme.Colors.fieldBorderVariant(scheme))
            .frame(height: 1)
            .padding(.vertical, 4)
    }

    // MARK: - Account Details

    private var accountDetailsSection: some View {
        VStack(spacing: 12) {
            // Name
            VStack(alignment: .leading, spacing: 4) {
                OutlinedTextField(
                    title: "Name",
                    text: Binding(get: { state.name }, set: { onEvent(.nameChanged($0)) }),
                    keyboard: .default,
                    textContentType: .name,
                    autocapitalization: .words
                )
                .focused($focus, equals: .name)
                .submitLabel(.next)
                .onSubmit { focus = .email }

                if let err = state.nameError {
                    errorLabel(err)
                }
            }

            // Email
            VStack(alignment: .leading, spacing: 4) {
                OutlinedTextField(
                    title: "Email",
                    text: Binding(get: { state.email }, set: { onEvent(.emailChanged($0)) }),
                    keyboard: .emailAddress,
                    textContentType: .emailAddress,
                    autocapitalization: .never
                )
                .focused($focus, equals: .email)
                .submitLabel(.next)
                .onSubmit { focus = .password }

                if let err = state.emailError {
                    errorLabel(err)
                }
            }

            // Password
            OutlinedPasswordField(
                title: "Password",
                text: Binding(get: { state.password }, set: { onEvent(.passwordChanged($0)) }),
                isVisible: state.isPasswordVisible,
                onToggleVisibility: { onEvent(.togglePasswordVisible) }
            )
            .focused($focus, equals: .password)
            .submitLabel(.next)
            .onSubmit { focus = .retypePassword }

            // Retype password
            OutlinedPasswordField(
                title: "Retype Password",
                text: Binding(get: { state.retypePassword }, set: { onEvent(.retypePasswordChanged($0)) }),
                isVisible: state.isRetypePasswordVisible,
                onToggleVisibility: { onEvent(.toggleRetypePasswordVisible) }
            )
            .focused($focus, equals: .retypePassword)
            .submitLabel(.done)
            .onSubmit { focus = nil }

            // Password rules
            VStack(alignment: .leading, spacing: 6) {
                ForEach(state.passwordRules, id: \.self) { rule in
                    HStack(alignment: .top, spacing: 8) {
                        Text("•")
                            .foregroundStyle(AppTheme.Colors.secondaryText(scheme))
                        Text(rule)
                            .font(.footnote)
                            .foregroundStyle(AppTheme.Colors.secondaryText(scheme))
                    }
                }
            }
            .padding(.top, 2)
        }
    }

    // MARK: - Shops Section

    private var shopsSection: some View {
        VStack(spacing: 12) {
            // Shop count row
            if !state.shops.isEmpty {
                HStack {
                    Text("\(state.shops.count) shop\(state.shops.count == 1 ? "" : "s") added")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(AppTheme.Colors.secondaryText(scheme))
                    Spacer()
                }
            }

            // Empty state
            if state.shops.isEmpty {
                emptyShopsView
            } else {
                VStack(spacing: 10) {
                    ForEach(state.shops) { shop in
                        shopCard(shop)
                    }
                }
            }

            // Add Shop button
            addShopButton

            // Default shop picker — only shown once shops exist
            if !state.shops.isEmpty {
                defaultShopSection
            }
        }
    }

    // MARK: Default Shop Section

    private var defaultShopSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 6) {
                Image(systemName: "star.fill")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(AppTheme.Colors.accent(scheme))
                Text("Default Shop")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(AppTheme.Colors.primaryText(scheme))
                Spacer()
                Text("Required")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(AppTheme.Colors.secondaryText(scheme))
            }

            VStack(spacing: 8) {
                ForEach(state.shops) { shop in
                    defaultShopRow(shop)
                }
            }
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: AppTheme.Layout.fieldCornerRadius, style: .continuous)
                .fill(AppTheme.Colors.surfaceContainer(scheme))
        )
        .overlay(
            RoundedRectangle(cornerRadius: AppTheme.Layout.fieldCornerRadius, style: .continuous)
                .strokeBorder(AppTheme.Colors.fieldBorderVariant(scheme), lineWidth: 1)
        )
    }

    @ViewBuilder
    private func defaultShopRow(_ shop: OwnerShopEntry) -> some View {
        let isSelected = state.defaultShopId == shop.id
        Button {
            onEvent(.defaultShopSelected(id: shop.id))
        } label: {
            HStack(spacing: 12) {
                // Radio indicator
                ZStack {
                    Circle()
                        .strokeBorder(
                            isSelected ? AppTheme.Colors.accent(scheme) : AppTheme.Colors.fieldBorder(scheme),
                            lineWidth: 1.5
                        )
                        .frame(width: 20, height: 20)
                    if isSelected {
                        Circle()
                            .fill(AppTheme.Colors.accent(scheme))
                            .frame(width: 11, height: 11)
                    }
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text(shop.name)
                        .font(.system(size: 14, weight: isSelected ? .semibold : .regular))
                        .foregroundStyle(
                            isSelected
                                ? AppTheme.Colors.primaryText(scheme)
                                : AppTheme.Colors.secondaryText(scheme)
                        )
                    Text(shop.address)
                        .font(.system(size: 11))
                        .foregroundStyle(AppTheme.Colors.secondaryText(scheme))
                        .lineLimit(1)
                }

                Spacer()

                if isSelected {
                    Image(systemName: "checkmark")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(AppTheme.Colors.accent(scheme))
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(isSelected
                        ? AppTheme.Colors.accent(scheme).opacity(0.08)
                        : Color.clear)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .strokeBorder(
                        isSelected ? AppTheme.Colors.accent(scheme) : Color.clear,
                        lineWidth: 1
                    )
            )
        }
        .buttonStyle(.plain)
        .animation(.easeInOut(duration: 0.15), value: isSelected)
    }

    // MARK: Empty shops placeholder

    private var emptyShopsView: some View {
        VStack(spacing: 10) {
            Image(systemName: "storefront")
                .font(.system(size: 30))
                .foregroundStyle(AppTheme.Colors.secondaryText(scheme))
            Text("No shops added yet")
                .font(AppTheme.Typography.caption)
                .foregroundStyle(AppTheme.Colors.secondaryText(scheme))
            Text("Add at least one shop to continue")
                .font(.system(size: 12))
                .foregroundStyle(AppTheme.Colors.secondaryText(scheme))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 28)
        .background(
            RoundedRectangle(cornerRadius: AppTheme.Layout.fieldCornerRadius, style: .continuous)
                .fill(AppTheme.Colors.surfaceContainer(scheme))
        )
    }

    // MARK: Shop card

    @ViewBuilder
    private func shopCard(_ shop: OwnerShopEntry) -> some View {
        HStack(alignment: .top, spacing: 12) {

            // Leading icon
            ZStack {
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(AppTheme.Colors.primaryContainer(scheme))
                    .frame(width: 40, height: 40)
                Image(systemName: "storefront.fill")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(AppTheme.Colors.onPrimaryContainer(scheme))
            }

            // Info
            VStack(alignment: .leading, spacing: 4) {
                Text(shop.name)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(AppTheme.Colors.primaryText(scheme))

                Text(shop.address)
                    .font(.system(size: 12))
                    .foregroundStyle(AppTheme.Colors.secondaryText(scheme))

                if !shop.phone.isEmpty {
                    shopMeta(icon: "phone.fill", text: shop.phone)
                }

                if !shop.locationLabel.isEmpty {
                    shopMeta(icon: "location.fill", text: shop.locationLabel)
                }
            }

            Spacer(minLength: 8)

            // Actions
            HStack(spacing: 4) {
                iconButton(systemName: "pencil", tint: AppTheme.Colors.accent(scheme)) {
                    onEvent(.editShopTapped(id: shop.id))
                }
                iconButton(systemName: "trash", tint: AppTheme.Colors.error(scheme)) {
                    onEvent(.deleteShopTapped(id: shop.id))
                }
            }
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: AppTheme.Layout.fieldCornerRadius, style: .continuous)
                .fill(AppTheme.Colors.surfaceContainer(scheme))
        )
        .overlay(
            RoundedRectangle(cornerRadius: AppTheme.Layout.fieldCornerRadius, style: .continuous)
                .strokeBorder(AppTheme.Colors.fieldBorderVariant(scheme), lineWidth: 1)
        )
    }

    @ViewBuilder
    private func shopMeta(icon: String, text: String) -> some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .font(.system(size: 10))
                .foregroundStyle(AppTheme.Colors.secondaryText(scheme))
            Text(text)
                .font(.system(size: 11))
                .foregroundStyle(AppTheme.Colors.secondaryText(scheme))
        }
    }

    // MARK: Add Shop button

    private var addShopButton: some View {
        Button {
            onEvent(.addShopTapped)
        } label: {
            HStack(spacing: 8) {
                Image(systemName: "plus.circle.fill")
                    .font(.system(size: 16, weight: .medium))
                Text("Add Shop")
                    .font(.system(size: 15, weight: .semibold))
            }
            .foregroundStyle(AppTheme.Colors.accent(scheme))
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(
                RoundedRectangle(cornerRadius: AppTheme.Layout.fieldCornerRadius, style: .continuous)
                    .fill(AppTheme.Colors.surfaceContainer(scheme))
            )
            .overlay(
                RoundedRectangle(cornerRadius: AppTheme.Layout.fieldCornerRadius, style: .continuous)
                    .strokeBorder(AppTheme.Colors.accent(scheme), lineWidth: 1.5)
            )
        }
        .buttonStyle(.plain)
    }

    // MARK: - Helpers

    @ViewBuilder
    private func errorLabel(_ text: String) -> some View {
        Text(text)
            .font(.caption)
            .foregroundStyle(AppTheme.Colors.error(scheme))
            .padding(.horizontal, 4)
    }

    @ViewBuilder
    private func iconButton(systemName: String, tint: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: systemName)
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(tint)
                .frame(width: 34, height: 34)
                .background(Circle().fill(AppTheme.Colors.surfaceContainer(scheme)))
        }
        .buttonStyle(.plain)
    }
}

// MARK: - ShopFormSheet
//
// Presented as a .sheet for both "Add Shop" and "Edit Shop".
// Reads draft state from OwnerSignUpUiState; emits events for field changes and save/cancel.

private struct ShopFormSheet: View {

    let state: OwnerSignUpUiState
    let onEvent: (OwnerSignUpUiEvent) -> Void

    @Environment(\.colorScheme) private var scheme

    private enum Field: Hashable { case name, address, phone }
    @FocusState private var focus: Field?

    var body: some View {
        VStack(spacing: 0) {

            // Drag handle
            Capsule()
                .fill(AppTheme.Colors.fieldBorderVariant(scheme))
                .frame(width: 36, height: 4)
                .padding(.top, 12)
                .padding(.bottom, 16)

            // Title
            Text(state.shopSheetTitle)
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(AppTheme.Colors.primaryText(scheme))
                .padding(.bottom, 18)

            Divider()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 14) {

                    // Shop Name
                    VStack(alignment: .leading, spacing: 4) {
                        OutlinedTextField(
                            title: "Shop Name *",
                            text: Binding(
                                get: { state.draftShop.name },
                                set: { onEvent(.draftShopNameChanged($0)) }
                            ),
                            keyboard: .default,
                            autocapitalization: .words
                        )
                        .focused($focus, equals: .name)
                        .submitLabel(.next)
                        .onSubmit { focus = .address }

                        if let err = state.draftShopNameError {
                            Text(err)
                                .font(.caption)
                                .foregroundStyle(AppTheme.Colors.error(scheme))
                                .padding(.horizontal, 4)
                        }
                    }

                    // Shop Address
                    VStack(alignment: .leading, spacing: 4) {
                        OutlinedTextField(
                            title: "Shop Address *",
                            text: Binding(
                                get: { state.draftShop.address },
                                set: { onEvent(.draftShopAddressChanged($0)) }
                            ),
                            keyboard: .default,
                            autocapitalization: .words
                        )
                        .focused($focus, equals: .address)
                        .submitLabel(.next)
                        .onSubmit { focus = .phone }

                        if let err = state.draftShopAddressError {
                            Text(err)
                                .font(.caption)
                                .foregroundStyle(AppTheme.Colors.error(scheme))
                                .padding(.horizontal, 4)
                        }
                    }

                    // Phone Number (masked)
                    OutlinedTextField(
                        title: "Shop Phone Number",
                        placeholder: "07700 900123",
                        text: Binding(
                            get: { state.draftShop.phone },
                            set: { onEvent(.draftShopPhoneChanged($0)) }
                        ),
                        keyboard: .phonePad
                    )
                    .focused($focus, equals: .phone)

                    // Location picker row
                    locationRow
                }
                .padding(.horizontal, AppTheme.Layout.screenHPadding)
                .padding(.top, 18)
                .padding(.bottom, 24)
            }
            .scrollDismissesKeyboard(.interactively)

            Divider()

            // Action buttons
            HStack(spacing: 12) {
                Button("Cancel") {
                    onEvent(.cancelShopSheetTapped)
                }
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(AppTheme.Colors.primaryText(scheme))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(
                    RoundedRectangle(cornerRadius: AppTheme.Layout.pillCornerRadious, style: .continuous)
                        .fill(AppTheme.Colors.surfaceContainer(scheme))
                )
                .buttonStyle(.plain)

                Button("Save Shop") {
                    focus = nil
                    onEvent(.saveShopTapped)
                }
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(AppTheme.Colors.buttonText(scheme))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(
                    RoundedRectangle(cornerRadius: AppTheme.Layout.pillCornerRadious, style: .continuous)
                        .fill(AppTheme.Colors.accent(scheme))
                )
                .buttonStyle(.plain)
            }
            .padding(.horizontal, AppTheme.Layout.screenHPadding)
            .padding(.top, 14)
            .padding(.bottom, 32)
        }
        .background(AppTheme.Colors.background(scheme))
    }

    // MARK: Location picker row (frontend stub)
    // MARK: Firebase – pending (will open Google Maps picker and populate lat/lng)

    private var locationRow: some View {
        Button {
            onEvent(.draftShopLocationTapped)
        } label: {
            VStack(alignment: .leading, spacing: 8) {
                Text("Shop Location")
                    .font(AppTheme.Typography.caption)
                    .foregroundStyle(AppTheme.Colors.secondaryText(scheme))

                HStack(spacing: 10) {
                    Image(systemName: "location.circle.fill")
                        .font(.system(size: 18))
                        .foregroundStyle(AppTheme.Colors.accent(scheme))

                    if state.draftShop.locationLabel.isEmpty {
                        Text("Tap to select location")
                            .font(AppTheme.Typography.fieldValue)
                            .foregroundStyle(AppTheme.Colors.secondaryText(scheme))
                    } else {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(state.draftShop.locationLabel)
                                .font(AppTheme.Typography.fieldValue)
                                .foregroundStyle(AppTheme.Colors.primaryText(scheme))
                            if let lat = state.draftShop.latitude,
                               let lng = state.draftShop.longitude {
                                Text(String(format: "%.5f, %.5f", lat, lng))
                                    .font(.system(size: 11))
                                    .foregroundStyle(AppTheme.Colors.secondaryText(scheme))
                            }
                        }
                    }

                    Spacer()

                    Image(systemName: "chevron.right")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(AppTheme.Colors.secondaryText(scheme))
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 14)
                .background(
                    RoundedRectangle(cornerRadius: AppTheme.Layout.fieldCornerRadius, style: .continuous)
                        .strokeBorder(AppTheme.Colors.fieldBorder(scheme), lineWidth: AppTheme.Layout.fieldBorderWidth)
                )
            }
        }
        .buttonStyle(.plain)
    }
}

// MARK: - DeleteConfirmSheet
//
// The user must type "CONFIRM" exactly before the delete button becomes enabled.

private struct DeleteConfirmSheet: View {

    let state: OwnerSignUpUiState
    let onEvent: (OwnerSignUpUiEvent) -> Void

    @Environment(\.colorScheme) private var scheme
    @FocusState private var isFieldFocused: Bool

    private var shopName: String {
        state.shops.first(where: { $0.id == state.shopPendingDeleteId })?.name ?? "this shop"
    }

    var body: some View {
        VStack(spacing: 0) {

            // Drag handle
            Capsule()
                .fill(AppTheme.Colors.fieldBorderVariant(scheme))
                .frame(width: 36, height: 4)
                .padding(.top, 12)
                .padding(.bottom, 20)

            VStack(spacing: 20) {

                // Warning icon
                ZStack {
                    Circle()
                        .fill(AppTheme.Colors.error(scheme).opacity(0.12))
                        .frame(width: 64, height: 64)
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.system(size: 26, weight: .semibold))
                        .foregroundStyle(AppTheme.Colors.error(scheme))
                }

                VStack(spacing: 8) {
                    Text("Remove Shop?")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundStyle(AppTheme.Colors.primaryText(scheme))

                    Text("\"\(shopName)\"")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(AppTheme.Colors.accent(scheme))

                    Text("This action is permanent and cannot be undone.")
                        .font(AppTheme.Typography.caption)
                        .foregroundStyle(AppTheme.Colors.secondaryText(scheme))
                        .multilineTextAlignment(.center)
                }

                // Confirm input
                VStack(alignment: .leading, spacing: 8) {
                    Text("Type \u{201C}CONFIRM\u{201D} to proceed")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(AppTheme.Colors.secondaryText(scheme))

                    TextField("", text: Binding(
                        get: { state.deleteConfirmText },
                        set: { onEvent(.deleteConfirmTextChanged($0)) }
                    ))
                    .font(AppTheme.Typography.fieldValue)
                    .autocorrectionDisabled(true)
                    .textInputAutocapitalization(.characters)
                    .focused($isFieldFocused)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 14)
                    .background(
                        RoundedRectangle(cornerRadius: AppTheme.Layout.fieldCornerRadius, style: .continuous)
                            .strokeBorder(
                                state.isDeleteConfirmValid
                                    ? AppTheme.Colors.error(scheme)
                                    : AppTheme.Colors.fieldBorder(scheme),
                                lineWidth: AppTheme.Layout.fieldBorderWidth
                            )
                    )
                }
            }
            .padding(.horizontal, AppTheme.Layout.screenHPadding)

            Spacer(minLength: 24)

            Divider()

            HStack(spacing: 12) {
                Button("Cancel") {
                    onEvent(.cancelDeleteTapped)
                }
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(AppTheme.Colors.primaryText(scheme))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(
                    RoundedRectangle(cornerRadius: AppTheme.Layout.pillCornerRadious, style: .continuous)
                        .fill(AppTheme.Colors.surfaceContainer(scheme))
                )
                .buttonStyle(.plain)

                Button("Remove") {
                    onEvent(.confirmDeleteTapped)
                }
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(state.isDeleteConfirmValid
                    ? AppTheme.Colors.buttonText(scheme)
                    : AppTheme.Colors.secondaryText(scheme))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(
                    RoundedRectangle(cornerRadius: AppTheme.Layout.pillCornerRadious, style: .continuous)
                        .fill(state.isDeleteConfirmValid
                            ? AppTheme.Colors.error(scheme)
                            : AppTheme.Colors.surfaceContainer(scheme))
                )
                .disabled(!state.isDeleteConfirmValid)
                .buttonStyle(.plain)
                .animation(.easeInOut(duration: 0.15), value: state.isDeleteConfirmValid)
            }
            .padding(.horizontal, AppTheme.Layout.screenHPadding)
            .padding(.top, 14)
            .padding(.bottom, 32)
        }
        .background(AppTheme.Colors.background(scheme))
        .onAppear { isFieldFocused = true }
    }
}

// MARK: - Previews

#Preview("OwnerSignUp - Light") {
    OwnerSignUpScreen(
        state: OwnerSignUpUiState(),
        onEvent: { _ in }
    )
    .preferredColorScheme(.light)
}

#Preview("OwnerSignUp - Dark") {
    OwnerSignUpScreen(
        state: OwnerSignUpUiState(),
        onEvent: { _ in }
    )
    .preferredColorScheme(.dark)
}

#Preview("OwnerSignUp - With Shops") {
    let state: OwnerSignUpUiState = {
        var s = OwnerSignUpUiState()
        s.name  = "Nishan Perera"
        s.email = "nishan@example.com"
        let shop1 = OwnerShopEntry(name: "South Lambeth Store",   address: "12 South Lambeth Rd, London SW8 1RT", phone: "02079 000123", locationLabel: "Vauxhall, London")
        let shop2 = OwnerShopEntry(name: "Stockwell Off Licence", address: "45 Stockwell Rd, London SW9 9BT",     phone: "02079 004567", locationLabel: "Stockwell, London")
        s.shops = [shop1, shop2]
        s.defaultShopId = shop1.id
        return s
    }()
    OwnerSignUpScreen(state: state, onEvent: { _ in })
        .preferredColorScheme(.light)
}

#Preview("OwnerSignUp - Delete Sheet") {
    let state: OwnerSignUpUiState = {
        var s = OwnerSignUpUiState()
        let shop = OwnerShopEntry(name: "South Lambeth Store", address: "12 South Lambeth Rd", phone: "07700 900123")
        s.shops = [shop]
        s.shopPendingDeleteId = shop.id
        s.isDeleteConfirmPresented = true
        return s
    }()
    DeleteConfirmSheet(state: state, onEvent: { _ in })
        .preferredColorScheme(.light)
}
