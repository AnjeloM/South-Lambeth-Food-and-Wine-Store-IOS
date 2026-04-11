import SwiftUI

// MARK: - SwitchShopScreen
//
// Owner mode  — add / edit / remove shops; tap a row to set as active (no confirm).
// User mode   — tap a row to open a confirmation dialog before switching.

public struct SwitchShopScreen: View {

    public let state: SwitchShopUiState
    public let onEvent: (SwitchShopUiEvent) -> Void

    public init(
        state: SwitchShopUiState,
        onEvent: @escaping (SwitchShopUiEvent) -> Void
    ) {
        self.state = state
        self.onEvent = onEvent
    }

    @Environment(\.colorScheme) private var scheme

    // MARK: - Sheet / dialog bindings

    private var deleteSheetBinding: Binding<Bool> {
        Binding(
            get: { state.deletingShopId != nil },
            set: { if !$0 { onEvent(.deleteSheetDismissed) } }
        )
    }

    private var shopFormBinding: Binding<Bool> {
        Binding(
            get: { state.isShopFormPresented },
            set: { if !$0 { onEvent(.shopFormDismissed) } }
        )
    }

    // MARK: - Body

    public var body: some View {
        ZStack {
            AppTheme.Colors.background(scheme).ignoresSafeArea()

            VStack(spacing: 0) {
                // Top bar — "Add" button only shown for owners
                AppTopBar(
                    title: "Manage Shop",
                    showBack: true,
                    showsShadow: true,
                    trailingContent: state.isOwner ? AnyView(addButton) : nil
                ) {
                    onEvent(.closeTapped)
                }

                if state.isLoadingShops {
                    Spacer()
                    ProgressView()
                        .progressViewStyle(.circular)
                        .tint(AppTheme.Colors.accent(scheme))
                        .scaleEffect(1.3)
                    Spacer()
                } else {
                    ScrollView(showsIndicators: false) {
                        VStack(spacing: 20) {
                            if state.isOwner {
                                ownerContent
                            } else {
                                userContent
                            }
                        }
                        .padding(.horizontal, AppTheme.Layout.screenHPadding)
                        .padding(.top, 20)
                        .padding(.bottom, 32)
                    }
                }
            }

            // MARK: Toast overlay
            if let toast = state.toastMessage {
                toastBanner(toast)
            }

            // MARK: Operation overlay (switching / deleting / setting default)
            if state.isSwitching || state.isDeletingShop || state.isSettingDefault {
                operationOverlay(
                    message: state.isSwitching
                        ? "Switching shop…"
                        : state.isSettingDefault
                            ? "Updating default…"
                            : "Removing shop…"
                )
            }
        }
        .onAppear { onEvent(.onAppear) }
        // MARK: Owner — shop form sheet
        .sheet(isPresented: shopFormBinding) {
            ShopFormSheet(
                isEditMode: state.editingShopId != nil,
                draftName: Binding(get: { state.draftName },    set: { onEvent(.draftNameChanged($0)) }),
                draftAddress: Binding(get: { state.draftAddress }, set: { onEvent(.draftAddressChanged($0)) }),
                draftPhone: Binding(get: { state.draftPhone },   set: { onEvent(.draftPhoneChanged($0)) }),
                isFormValid: state.isFormValid,
                onSave: { onEvent(.saveShopTapped) },
                onDismiss: { onEvent(.shopFormDismissed) }
            )
            .presentationDetents([.medium, .large])
            .presentationDragIndicator(.hidden)
        }
        // MARK: Owner — delete confirm sheet
        .sheet(isPresented: deleteSheetBinding) {
            if let shop = state.shopBeingDeleted {
                DeleteConfirmSheet(
                    shopName: shop.name,
                    confirmText: Binding(
                        get: { state.deleteConfirmText },
                        set: { onEvent(.deleteConfirmTextChanged($0)) }
                    ),
                    isConfirmValid: state.isDeleteConfirmValid,
                    onConfirm: { onEvent(.confirmDeleteTapped) },
                    onDismiss: { onEvent(.deleteSheetDismissed) }
                )
                .presentationDetents([.medium])
                .presentationDragIndicator(.hidden)
            }
        }
        // MARK: User — switch confirm alert
        .alert(
            "Switch Shop",
            isPresented: Binding(
                get: { state.pendingSwitchShopId != nil },
                set: { if !$0 { onEvent(.switchCancelled) } }
            )
        ) {
            Button("Switch", role: .none) { onEvent(.switchConfirmed) }
            Button("Cancel", role: .cancel) { onEvent(.switchCancelled) }
        } message: {
            if let shop = state.pendingSwitchShop {
                Text("Switch to \(shop.name)?")
            }
        }
    }

    // MARK: - Add button (owner top bar)

    private var addButton: some View {
        Button {
            onEvent(.addShopTapped)
        } label: {
            Image(systemName: "plus")
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(AppTheme.Colors.accent(scheme))
                .frame(width: 36, height: 36)
                .background(AppTheme.Colors.surfaceContainer(scheme))
                .clipShape(Circle())
        }
        .buttonStyle(.plain)
        .padding(.trailing, 4)
    }

    // MARK: - Owner Content

    @ViewBuilder
    private var ownerContent: some View {
        if state.shops.isEmpty {
            emptyOwnerView
        } else {
            sectionBlock(title: "Your Shops") {
                VStack(spacing: 10) {
                    ForEach(state.shops) { shop in
                        ownerShopRow(shop)
                    }
                }
            }
        }
    }

    // MARK: - User Content

    @ViewBuilder
    private var userContent: some View {
        if state.shops.isEmpty {
            emptyOtherShopsView
        } else {
            sectionBlock(title: "Your Shops") {
                VStack(spacing: 10) {
                    ForEach(state.shops) { shop in
                        userShopRow(shop)
                    }
                }
            }
        }
    }

    // MARK: - Owner Shop Row

    @ViewBuilder
    private func ownerShopRow(_ shop: SwitchShopEntry) -> some View {
        HStack(spacing: 14) {
            // Icon
            shopIcon(shop)

            // Info
            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 6) {
                    Text(shop.name)
                        .font(.system(size: 15, weight: shop.isDefaultShop ? .semibold : .medium))
                        .foregroundStyle(AppTheme.Colors.primaryText(scheme))
                    if shop.isDefaultShop {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(.green)
                    }
                }
                Text(shop.address)
                    .font(.system(size: 12))
                    .foregroundStyle(AppTheme.Colors.secondaryText(scheme))
                    .lineLimit(1)
                if !shop.phone.isEmpty {
                    Text(shop.phone)
                        .font(.system(size: 11))
                        .foregroundStyle(AppTheme.Colors.secondaryText(scheme))
                }
            }

            Spacer(minLength: 8)

            // Action buttons
            HStack(spacing: 6) {
                // ON/OFF toggle — sets this shop as active for all users
                Button {
                    onEvent(.setDefaultShopTapped(id: shop.id))
                } label: {
                    activeToggle(isOn: shop.isDefaultShop)
                }
                .buttonStyle(.plain)
                .disabled(shop.isDefaultShop || state.isSettingDefault)
                .animation(.spring(response: 0.28, dampingFraction: 0.7), value: shop.isDefaultShop)

                // Edit
                Button {
                    onEvent(.editShopTapped(id: shop.id))
                } label: {
                    Image(systemName: "pencil")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(AppTheme.Colors.accent(scheme))
                        .frame(width: 34, height: 34)
                        .background(AppTheme.Colors.surfaceContainer(scheme))
                        .clipShape(Circle())
                }
                .buttonStyle(.plain)

                // Delete
                Button {
                    onEvent(.deleteShopTapped(id: shop.id))
                } label: {
                    Image(systemName: "trash")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(AppTheme.Colors.error(scheme))
                        .frame(width: 34, height: 34)
                        .background(AppTheme.Colors.error(scheme).opacity(0.1))
                        .clipShape(Circle())
                }
                .buttonStyle(.plain)
            }
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: AppTheme.Layout.fieldCornerRadius, style: .continuous)
                .fill(shop.isDefaultShop
                    ? AppTheme.Colors.accent(scheme).opacity(0.06)
                    : AppTheme.Colors.surfaceContainer(scheme))
        )
        .overlay(
            RoundedRectangle(cornerRadius: AppTheme.Layout.fieldCornerRadius, style: .continuous)
                .strokeBorder(
                    shop.isDefaultShop
                        ? AppTheme.Colors.accent(scheme).opacity(0.4)
                        : AppTheme.Colors.fieldBorderVariant(scheme),
                    lineWidth: shop.isDefaultShop ? 1.5 : 1
                )
        )
    }

    // MARK: - User Shop Row

    @ViewBuilder
    private func userShopRow(_ shop: SwitchShopEntry) -> some View {
        HStack(spacing: 14) {
            shopIcon(shop)

            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 6) {
                    Text(shop.name)
                        .font(.system(size: 15, weight: shop.isCurrentShop ? .semibold : .medium))
                        .foregroundStyle(AppTheme.Colors.primaryText(scheme))
                    if shop.isCurrentShop {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(.green)
                    }
                }
                Text(shop.address)
                    .font(.system(size: 12))
                    .foregroundStyle(AppTheme.Colors.secondaryText(scheme))
                    .lineLimit(1)
            }

            Spacer(minLength: 8)

            // ON/OFF toggle — tapping sets this shop as current for this user (confirm alert)
            Button {
                onEvent(.shopTapped(id: shop.id))
            } label: {
                activeToggle(isOn: shop.isCurrentShop)
            }
            .buttonStyle(.plain)
            .disabled(shop.isCurrentShop || state.isSwitching)
            .animation(.spring(response: 0.28, dampingFraction: 0.7), value: shop.isCurrentShop)
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: AppTheme.Layout.fieldCornerRadius, style: .continuous)
                .fill(shop.isCurrentShop
                    ? AppTheme.Colors.accent(scheme).opacity(0.06)
                    : AppTheme.Colors.surfaceContainer(scheme))
        )
        .overlay(
            RoundedRectangle(cornerRadius: AppTheme.Layout.fieldCornerRadius, style: .continuous)
                .strokeBorder(
                    shop.isCurrentShop
                        ? AppTheme.Colors.accent(scheme).opacity(0.4)
                        : AppTheme.Colors.fieldBorderVariant(scheme),
                    lineWidth: shop.isCurrentShop ? 1.5 : 1
                )
        )
    }

    // MARK: - Shared Icon

    private func shopIcon(_ shop: SwitchShopEntry) -> some View {
        let isActive = state.isOwner ? shop.isDefaultShop : shop.isCurrentShop
        return ZStack {
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(isActive
                    ? AppTheme.Colors.accent(scheme).opacity(0.15)
                    : AppTheme.Colors.primaryContainer(scheme))
                .frame(width: 44, height: 44)
            Image(systemName: isActive ? "storefront.fill" : "storefront")
                .font(.system(size: 18, weight: .medium))
                .foregroundStyle(isActive
                    ? AppTheme.Colors.accent(scheme)
                    : AppTheme.Colors.onPrimaryContainer(scheme))
        }
    }

    // MARK: - Section Block

    @ViewBuilder
    private func sectionBlock<Content: View>(
        title: String,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(AppTheme.Colors.secondaryText(scheme))
                .padding(.horizontal, 4)
            content()
        }
    }

    // MARK: - Active Toggle (iOS-style pill switch)

    private func activeToggle(isOn: Bool) -> some View {
        ZStack(alignment: isOn ? .trailing : .leading) {
            Capsule()
                .fill(isOn
                    ? AppTheme.Colors.accent(scheme)
                    : AppTheme.Colors.fieldBorderVariant(scheme).opacity(0.6))
                .frame(width: 46, height: 26)
            ZStack {
                Circle()
                    .fill(.white)
                    .frame(width: 20, height: 20)
                    .shadow(color: .black.opacity(0.18), radius: 2, x: 0, y: 1)
                if isOn {
                    Image(systemName: "checkmark")
                        .font(.system(size: 9, weight: .bold))
                        .foregroundStyle(AppTheme.Colors.accent(scheme))
                }
            }
            .padding(.horizontal, 3)
        }
    }

    // MARK: - Empty States

    private var emptyOtherShopsView: some View {
        VStack(spacing: 10) {
            Image(systemName: "storefront")
                .font(.system(size: 30))
                .foregroundStyle(AppTheme.Colors.secondaryText(scheme))
            Text("No shops assigned")
                .font(AppTheme.Typography.caption)
                .foregroundStyle(AppTheme.Colors.secondaryText(scheme))
            Text("Ask your owner to assign you to a shop")
                .font(.system(size: 12))
                .foregroundStyle(AppTheme.Colors.secondaryText(scheme))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 32)
        .background(
            RoundedRectangle(cornerRadius: AppTheme.Layout.fieldCornerRadius, style: .continuous)
                .fill(AppTheme.Colors.surfaceContainer(scheme))
        )
    }

    private var emptyOwnerView: some View {
        VStack(spacing: 12) {
            Image(systemName: "storefront.slash")
                .font(.system(size: 34))
                .foregroundStyle(AppTheme.Colors.secondaryText(scheme))
            Text("No shops yet")
                .font(AppTheme.Typography.caption)
                .foregroundStyle(AppTheme.Colors.primaryText(scheme))
            Text("Tap + to add your first shop")
                .font(.system(size: 13))
                .foregroundStyle(AppTheme.Colors.secondaryText(scheme))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 48)
    }

    // MARK: - Operation Overlay

    private func operationOverlay(message: String) -> some View {
        ZStack {
            Color.black.opacity(0.35).ignoresSafeArea()
            VStack(spacing: 14) {
                ProgressView()
                    .progressViewStyle(.circular)
                    .tint(AppTheme.Colors.accent(scheme))
                    .scaleEffect(1.3)
                Text(message)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(.white)
            }
            .padding(28)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(Color.black.opacity(0.75))
            )
        }
    }

    // MARK: - Toast Banner

    @ViewBuilder
    private func toastBanner(_ message: String) -> some View {
        VStack {
            Spacer()
            HStack(spacing: 10) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 16))
                    .foregroundStyle(AppTheme.Colors.accent(scheme))
                Text(message)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(AppTheme.Colors.primaryText(scheme))
            }
            .padding(.horizontal, 18)
            .padding(.vertical, 14)
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(AppTheme.Colors.surface(scheme))
                    .shadow(color: .black.opacity(0.12), radius: 10, x: 0, y: 4)
            )
            .padding(.horizontal, AppTheme.Layout.screenHPadding)
            .padding(.bottom, 28)
            .transition(.move(edge: .bottom).combined(with: .opacity))
        }
        .animation(.spring(response: 0.35, dampingFraction: 0.8), value: state.toastMessage != nil)
    }
}

// MARK: - ShopFormSheet (owner add / edit)

private struct ShopFormSheet: View {

    let isEditMode: Bool
    @Binding var draftName: String
    @Binding var draftAddress: String
    @Binding var draftPhone: String
    let isFormValid: Bool
    let onSave: () -> Void
    let onDismiss: () -> Void

    @Environment(\.colorScheme) private var scheme
    @FocusState private var focusedField: FormField?

    private enum FormField { case name, address, phone }

    var body: some View {
        VStack(spacing: 0) {
            // Drag handle
            Capsule()
                .fill(AppTheme.Colors.fieldBorderVariant(scheme))
                .frame(width: 36, height: 4)
                .padding(.top, 12)
                .padding(.bottom, 14)

            Text(isEditMode ? "Edit Shop" : "Add Shop")
                .font(.system(size: 17, weight: .semibold))
                .foregroundStyle(AppTheme.Colors.primaryText(scheme))
                .padding(.bottom, 20)

            VStack(spacing: 14) {
                OutlinedTextField(
                    title: "Shop Name *",
                    text: $draftName,
                    keyboard: .default,
                    autocapitalization: .words
                )
                .focused($focusedField, equals: .name)
                .submitLabel(.next)
                .onSubmit { focusedField = .address }

                OutlinedTextField(
                    title: "Address *",
                    text: $draftAddress,
                    keyboard: .default,
                    autocapitalization: .words
                )
                .focused($focusedField, equals: .address)
                .submitLabel(.next)
                .onSubmit { focusedField = .phone }

                OutlinedTextField(
                    title: "Phone (optional)",
                    text: $draftPhone,
                    keyboard: .phonePad
                )
                .focused($focusedField, equals: .phone)
                .submitLabel(.done)
                .onSubmit { focusedField = nil }
            }
            .padding(.horizontal, AppTheme.Layout.screenHPadding)

            Spacer()

            Divider().padding(.top, 20)

            HStack(spacing: 12) {
                Button("Cancel") { onDismiss() }
                    .font(.system(size: 16, weight: .medium))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(AppTheme.Colors.surfaceContainer(scheme))
                    .foregroundStyle(AppTheme.Colors.primaryText(scheme))
                    .clipShape(RoundedRectangle(cornerRadius: AppTheme.Layout.fieldCornerRadius, style: .continuous))
                    .buttonStyle(.plain)

                Button(isEditMode ? "Save Changes" : "Add Shop") { onSave() }
                    .font(.system(size: 16, weight: .semibold))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(isFormValid
                        ? AppTheme.Colors.accent(scheme)
                        : AppTheme.Colors.accent(scheme).opacity(0.35))
                    .foregroundStyle(AppTheme.Colors.buttonText(scheme))
                    .clipShape(RoundedRectangle(cornerRadius: AppTheme.Layout.fieldCornerRadius, style: .continuous))
                    .buttonStyle(.plain)
                    .disabled(!isFormValid)
            }
            .padding(.horizontal, AppTheme.Layout.screenHPadding)
            .padding(.top, 14)
            .padding(.bottom, 32)
        }
        .background(AppTheme.Colors.background(scheme))
    }
}

// MARK: - DeleteConfirmSheet (owner remove)

private struct DeleteConfirmSheet: View {

    let shopName: String
    @Binding var confirmText: String
    let isConfirmValid: Bool
    let onConfirm: () -> Void
    let onDismiss: () -> Void

    @Environment(\.colorScheme) private var scheme
    @FocusState private var isFieldFocused: Bool

    var body: some View {
        VStack(spacing: 0) {
            // Drag handle
            Capsule()
                .fill(AppTheme.Colors.fieldBorderVariant(scheme))
                .frame(width: 36, height: 4)
                .padding(.top, 12)
                .padding(.bottom, 16)

            // Warning icon
            ZStack {
                Circle()
                    .fill(AppTheme.Colors.error(scheme).opacity(0.12))
                    .frame(width: 60, height: 60)
                Image(systemName: "trash.fill")
                    .font(.system(size: 24, weight: .medium))
                    .foregroundStyle(AppTheme.Colors.error(scheme))
            }
            .padding(.bottom, 14)

            Text("Remove \"\(shopName)\"?")
                .font(.system(size: 17, weight: .semibold))
                .foregroundStyle(AppTheme.Colors.primaryText(scheme))
                .multilineTextAlignment(.center)
                .padding(.bottom, 8)

            Text("This action cannot be undone. Type **CONFIRM** below to enable the remove button.")
                .font(.system(size: 13))
                .foregroundStyle(AppTheme.Colors.secondaryText(scheme))
                .multilineTextAlignment(.center)
                .padding(.horizontal, AppTheme.Layout.screenHPadding)
                .padding(.bottom, 20)

            // Confirm text field
            OutlinedTextField(
                title: "Type CONFIRM",
                text: $confirmText,
                keyboard: .default,
                autocapitalization: .characters
            )
            .focused($isFieldFocused)
            .padding(.horizontal, AppTheme.Layout.screenHPadding)

            Spacer()

            Divider().padding(.top, 20)

            HStack(spacing: 12) {
                Button("Cancel") { onDismiss() }
                    .font(.system(size: 16, weight: .medium))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(AppTheme.Colors.surfaceContainer(scheme))
                    .foregroundStyle(AppTheme.Colors.primaryText(scheme))
                    .clipShape(RoundedRectangle(cornerRadius: AppTheme.Layout.fieldCornerRadius, style: .continuous))
                    .buttonStyle(.plain)

                Button("Remove Shop") { onConfirm() }
                    .font(.system(size: 16, weight: .semibold))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(isConfirmValid
                        ? AppTheme.Colors.error(scheme)
                        : AppTheme.Colors.error(scheme).opacity(0.25))
                    .foregroundStyle(isConfirmValid ? .white : AppTheme.Colors.error(scheme).opacity(0.6))
                    .clipShape(RoundedRectangle(cornerRadius: AppTheme.Layout.fieldCornerRadius, style: .continuous))
                    .buttonStyle(.plain)
                    .disabled(!isConfirmValid)
                    .animation(.easeInOut(duration: 0.2), value: isConfirmValid)
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

#Preview("ManageShop - User - Light") {
    SwitchShopScreen(
        state: {
            var s = SwitchShopUiState()
            s.shops = SwitchShopUiState.mockShops
            s.isOwner = false
            return s
        }(),
        onEvent: { _ in }
    )
    .preferredColorScheme(.light)
}

#Preview("ManageShop - User - Dark") {
    SwitchShopScreen(
        state: {
            var s = SwitchShopUiState()
            s.shops = SwitchShopUiState.mockShops
            s.isOwner = false
            return s
        }(),
        onEvent: { _ in }
    )
    .preferredColorScheme(.dark)
}

#Preview("ManageShop - Owner - Light") {
    SwitchShopScreen(
        state: {
            var s = SwitchShopUiState()
            s.shops = SwitchShopUiState.mockShops
            s.isOwner = true
            return s
        }(),
        onEvent: { _ in }
    )
    .preferredColorScheme(.light)
}

#Preview("ManageShop - Owner - Dark") {
    SwitchShopScreen(
        state: {
            var s = SwitchShopUiState()
            s.shops = SwitchShopUiState.mockShops
            s.isOwner = true
            return s
        }(),
        onEvent: { _ in }
    )
    .preferredColorScheme(.dark)
}

#Preview("ManageShop - Owner - Empty") {
    SwitchShopScreen(
        state: {
            var s = SwitchShopUiState()
            s.isOwner = true
            return s
        }(),
        onEvent: { _ in }
    )
    .preferredColorScheme(.light)
}
