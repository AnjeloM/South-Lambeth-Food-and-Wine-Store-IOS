import SwiftUI

// MARK: - JoinShopScreen

public struct JoinShopScreen: View {

    public let state: JoinShopUiState
    public let onEvent: (JoinShopUiEvent) -> Void

    public init(state: JoinShopUiState, onEvent: @escaping (JoinShopUiEvent) -> Void) {
        self.state = state
        self.onEvent = onEvent
    }

    @Environment(\.colorScheme) private var scheme

    // MARK: - Body

    public var body: some View {
        ZStack {
            AppTheme.Colors.background(scheme).ignoresSafeArea()

            if state.isCheckingPending {
                checkingView
            } else if state.requestSent || state.pendingRequest != nil {
                successView
            } else {
                selectionView
            }

            if state.isSubmitting {
                AppLoadingOverlay()
            }
        }
        .onAppear { onEvent(.onAppear) }
        .sheet(isPresented: Binding(
            get: { state.isOwnerPickerPresented },
            set: { if !$0 { onEvent(.ownerPickerDismissed) } }
        )) {
            shopSearchSheet
        }
    }

    // MARK: - Checking State

    private var checkingView: some View {
        VStack(spacing: 16) {
            ProgressView()
                .progressViewStyle(.circular)
                .tint(AppTheme.Colors.accent(scheme))
                .scaleEffect(1.3)
            Text("Checking account status…")
                .font(.system(size: 14))
                .foregroundStyle(AppTheme.Colors.secondaryText(scheme))
        }
    }

    // MARK: - Selection View

    private var selectionView: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 0) {

                // MARK: Header
                VStack(spacing: 12) {
                    ZStack {
                        Circle()
                            .fill(AppTheme.Colors.accent(scheme).opacity(0.12))
                            .frame(width: 80, height: 80)
                        Image(systemName: "storefront.fill")
                            .font(.system(size: 36, weight: .medium))
                            .foregroundStyle(AppTheme.Colors.accent(scheme))
                    }
                    .padding(.top, 60)

                    Text("Request Shop Access")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundStyle(AppTheme.Colors.primaryText(scheme))
                        .multilineTextAlignment(.center)

                    Text("Search for your shop by name or employer\nto request access from your manager.")
                        .font(.system(size: 14))
                        .foregroundStyle(AppTheme.Colors.secondaryText(scheme))
                        .multilineTextAlignment(.center)
                        .lineSpacing(3)
                }
                .padding(.horizontal, AppTheme.Layout.screenHPadding)
                .padding(.bottom, 36)

                // MARK: Form cards
                VStack(spacing: 14) {

                    // Employer (auto-filled)
                    if let owner = state.selectedOwner {
                        pickerCard(
                            icon: "person.fill",
                            label: "Employer",
                            value: owner.name
                        ) { onEvent(.ownerPickerTapped) }
                    }

                    // Shop search / selection card
                    pickerCard(
                        icon: "storefront",
                        label: state.selectedOwner == nil ? "Shop" : "Selected Shop",
                        value: state.selectedShop?.name,
                        placeholder: "Search by shop or employer name"
                    ) { onEvent(.ownerPickerTapped) }

                    if let shop = state.selectedShop {
                        Text(shop.address)
                            .font(.system(size: 12))
                            .foregroundStyle(AppTheme.Colors.secondaryText(scheme))
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal, 4)
                            .padding(.top, -6)
                    }
                }
                .padding(.horizontal, AppTheme.Layout.screenHPadding)

                // MARK: Submit
                AppPillButton(
                    title: "Send Request",
                    isEnabled: state.isFormValid,
                    action: { onEvent(.submitTapped) }
                )
                .padding(.horizontal, AppTheme.Layout.screenHPadding)
                .padding(.top, 28)

                // MARK: Logout
                Button { onEvent(.logoutTapped) } label: {
                    Text("Log Out")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(AppTheme.Colors.error(scheme))
                }
                .buttonStyle(.plain)
                .padding(.top, 20)
                .padding(.bottom, 40)
            }
        }
    }

    // MARK: - Success / Pending View

    private var successView: some View {
        VStack(spacing: 0) {
            Spacer()

            VStack(spacing: 20) {
                ZStack {
                    Circle()
                        .fill(AppTheme.Colors.accent(scheme).opacity(0.12))
                        .frame(width: 96, height: 96)
                    Image(systemName: "clock.badge.checkmark.fill")
                        .font(.system(size: 46, weight: .medium))
                        .foregroundStyle(AppTheme.Colors.accent(scheme))
                }

                Text(state.pendingRequest != nil && !state.requestSent
                     ? "Request Already Sent"
                     : "Request Sent!")
                    .font(.system(size: 26, weight: .bold))
                    .foregroundStyle(AppTheme.Colors.primaryText(scheme))

                VStack(spacing: 8) {
                    let shopName = state.requestSent
                        ? state.selectedShop?.name
                        : state.pendingRequest?.shopName

                    if let shopName {
                        Text("Your request to join **\(shopName)** is pending.")
                            .font(.system(size: 15))
                            .foregroundStyle(AppTheme.Colors.primaryText(scheme))
                            .multilineTextAlignment(.center)
                    }

                    if let ownerName = state.selectedOwner?.name, state.requestSent {
                        Text("**\(ownerName)** will be notified and can approve your request.")
                            .font(.system(size: 14))
                            .foregroundStyle(AppTheme.Colors.secondaryText(scheme))
                            .multilineTextAlignment(.center)
                    } else {
                        Text("Your manager will be notified and can approve your request.")
                            .font(.system(size: 14))
                            .foregroundStyle(AppTheme.Colors.secondaryText(scheme))
                            .multilineTextAlignment(.center)
                    }

                    Text("You’ll be able to access Home after your request is approved.")
                        .font(.system(size: 13))
                        .foregroundStyle(AppTheme.Colors.secondaryText(scheme).opacity(0.8))
                        .multilineTextAlignment(.center)
                        .padding(.top, 2)
                }
                .padding(.horizontal, AppTheme.Layout.screenHPadding)
            }

            Spacer()

            Button { onEvent(.logoutTapped) } label: {
                Text("Log Out")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(AppTheme.Colors.error(scheme))
            }
            .buttonStyle(.plain)
            .padding(.bottom, 48)
        }
    }

    // MARK: - Picker Card

    @ViewBuilder
    private func pickerCard(
        icon: String,
        label: String,
        value: String? = nil,
        placeholder: String = "",
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(AppTheme.Colors.accent(scheme))
                    .frame(width: 24)

                VStack(alignment: .leading, spacing: 2) {
                    Text(label.uppercased())
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundStyle(AppTheme.Colors.secondaryText(scheme).opacity(0.7))
                        .tracking(0.8)

                    if let value {
                        Text(value)
                            .font(.system(size: 14, weight: .medium))
                            .foregroundStyle(AppTheme.Colors.primaryText(scheme))
                            .lineLimit(1)
                    } else {
                        Text(placeholder)
                            .font(.system(size: 14))
                            .foregroundStyle(AppTheme.Colors.secondaryText(scheme))
                    }
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(AppTheme.Colors.secondaryText(scheme).opacity(0.6))
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: AppTheme.Layout.fieldCornerRadius, style: .continuous)
                    .fill(AppTheme.Colors.surfaceContainer(scheme))
            )
            .overlay(
                RoundedRectangle(cornerRadius: AppTheme.Layout.fieldCornerRadius, style: .continuous)
                    .strokeBorder(
                        value != nil
                            ? AppTheme.Colors.accent(scheme).opacity(0.45)
                            : AppTheme.Colors.fieldBorderVariant(scheme),
                        lineWidth: value != nil ? 1.5 : 1
                    )
            )
        }
        .buttonStyle(.plain)
    }

    // MARK: - Shop Search Sheet

    private var shopSearchSheet: some View {
        NavigationStack {
            VStack(spacing: 0) {

                // MARK: Search bar
                HStack(spacing: 10) {
                    Image(systemName: "magnifyingglass")
                        .font(.system(size: 15, weight: .medium))
                        .foregroundStyle(
                            state.ownerSearchText.isEmpty
                                ? AppTheme.Colors.secondaryText(scheme)
                                : AppTheme.Colors.accent(scheme)
                        )

                    TextField("Shop or employer name…", text: Binding(
                        get: { state.ownerSearchText },
                        set: { onEvent(.ownerSearchChanged($0)) }
                    ))
                    .font(.system(size: 15))
                    .foregroundStyle(AppTheme.Colors.primaryText(scheme))
                    .autocorrectionDisabled()
                    .textInputAutocapitalization(.words)

                    if !state.ownerSearchText.isEmpty {
                        Button { onEvent(.ownerSearchChanged("")) } label: {
                            Image(systemName: "xmark.circle.fill")
                                .font(.system(size: 15))
                                .foregroundStyle(AppTheme.Colors.secondaryText(scheme))
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 12)
                .background(AppTheme.Colors.surfaceContainer(scheme))
                .clipShape(RoundedRectangle(cornerRadius: AppTheme.Layout.fieldCornerRadius, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: AppTheme.Layout.fieldCornerRadius, style: .continuous)
                        .strokeBorder(AppTheme.Colors.fieldBorderVariant(scheme), lineWidth: 1)
                )
                .padding(.horizontal, AppTheme.Layout.screenHPadding)
                .padding(.top, 12)
                .padding(.bottom, 8)

                Divider()

                // MARK: Content area
                Group {
                    if !state.canSearch {
                        searchHint
                    } else if state.isSearchingOwners {
                        searchLoading
                    } else if state.ownerSearchIsEmpty {
                        searchEmpty
                    } else {
                        searchTree
                    }
                }
            }
            .background(AppTheme.Colors.background(scheme).ignoresSafeArea())
            .navigationTitle("Find Your Shop")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { onEvent(.ownerPickerDismissed) }
                }
            }
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.hidden)
    }

    // MARK: Hint / Loading / Empty

    private var searchHint: some View {
        VStack(spacing: 10) {
            Spacer()
            Image(systemName: "magnifyingglass")
                .font(.system(size: 30))
                .foregroundStyle(AppTheme.Colors.secondaryText(scheme).opacity(0.4))
            Text("Type at least 2 characters")
                .font(.system(size: 15, weight: .medium))
                .foregroundStyle(AppTheme.Colors.secondaryText(scheme))
            Text("Search by shop name or employer name")
                .font(.system(size: 13))
                .foregroundStyle(AppTheme.Colors.secondaryText(scheme).opacity(0.7))
            Spacer()
        }
        .frame(maxWidth: .infinity)
    }

    private var searchLoading: some View {
        VStack(spacing: 12) {
            Spacer()
            ProgressView()
                .progressViewStyle(.circular)
                .tint(AppTheme.Colors.accent(scheme))
                .scaleEffect(1.2)
            Text("Searching…")
                .font(.system(size: 14))
                .foregroundStyle(AppTheme.Colors.secondaryText(scheme))
            Spacer()
        }
        .frame(maxWidth: .infinity)
    }

    private var searchEmpty: some View {
        VStack(spacing: 10) {
            Spacer()
            Image(systemName: "storefront.slash")
                .font(.system(size: 30))
                .foregroundStyle(AppTheme.Colors.secondaryText(scheme).opacity(0.4))
            Text("No shops found")
                .font(.system(size: 15, weight: .medium))
                .foregroundStyle(AppTheme.Colors.secondaryText(scheme))
            Text("Try a different shop or employer name.")
                .font(.system(size: 13))
                .foregroundStyle(AppTheme.Colors.secondaryText(scheme).opacity(0.7))
                .multilineTextAlignment(.center)
                .padding(.horizontal, AppTheme.Layout.screenHPadding)
            Spacer()
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Tree Results

    private var searchTree: some View {
        List {
            ForEach(state.ownerSearchResults) { owner in
                // MARK: Owner section
                Section {
                    ForEach(owner.shops) { shop in
                        shopRow(shop, owner: owner)
                    }
                } header: {
                    ownerHeader(owner)
                }
            }
        }
        .listStyle(.insetGrouped)
        .scrollContentBackground(.hidden)
        .background(AppTheme.Colors.background(scheme))
    }

    // MARK: Owner header row

    @ViewBuilder
    private func ownerHeader(_ owner: SignUpOwner) -> some View {
        HStack(spacing: 10) {
            ZStack {
                Circle()
                    .fill(AppTheme.Colors.accent(scheme).opacity(0.15))
                    .frame(width: 30, height: 30)
                Image(systemName: "person.fill")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(AppTheme.Colors.accent(scheme))
            }

            VStack(alignment: .leading, spacing: 1) {
                Text(owner.name)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(AppTheme.Colors.primaryText(scheme))
                Text("\(owner.shops.count) shop\(owner.shops.count == 1 ? "" : "s")")
                    .font(.system(size: 11))
                    .foregroundStyle(AppTheme.Colors.secondaryText(scheme))
            }
        }
        .padding(.vertical, 4)
        .textCase(nil)
    }

    // MARK: Shop leaf row

    @ViewBuilder
    private func shopRow(_ shop: SignUpShop, owner: SignUpOwner) -> some View {
        let isSelected = state.selectedShop?.id == shop.id

        Button {
            onEvent(.shopSelected(shop, owner: owner))
        } label: {
            HStack(spacing: 12) {
                ZStack {
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .fill(isSelected
                              ? AppTheme.Colors.accent(scheme)
                              : AppTheme.Colors.primaryContainer(scheme))
                        .frame(width: 36, height: 36)
                    Image(systemName: "storefront.fill")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(isSelected
                                         ? AppTheme.Colors.buttonText(scheme)
                                         : AppTheme.Colors.onPrimaryContainer(scheme))
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text(shop.name)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(AppTheme.Colors.primaryText(scheme))
                        .lineLimit(1)
                    Text(shop.address)
                        .font(.system(size: 12))
                        .foregroundStyle(AppTheme.Colors.secondaryText(scheme))
                        .lineLimit(1)
                }

                Spacer()

                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 18))
                        .foregroundStyle(AppTheme.Colors.accent(scheme))
                }
            }
            .padding(.vertical, 4)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .listRowBackground(
            isSelected
                ? AppTheme.Colors.accent(scheme).opacity(0.06)
                : AppTheme.Colors.surfaceContainer(scheme)
        )
        .animation(.easeInOut(duration: 0.15), value: isSelected)
    }
}

// MARK: - Previews

#Preview("JoinShop - Initial - Light") {
    JoinShopScreen(state: JoinShopUiState(), onEvent: { _ in })
        .preferredColorScheme(.light)
}

#Preview("JoinShop - Searching - Dark") {
    JoinShopScreen(
        state: {
            var s = JoinShopUiState()
            s.ownerSearchText = "So"
            s.isSearchingOwners = true
            s.isOwnerPickerPresented = true
            return s
        }(),
        onEvent: { _ in }
    )
    .preferredColorScheme(.dark)
}

#Preview("JoinShop - Tree Results - Light") {
    JoinShopScreen(
        state: {
            var s = JoinShopUiState()
            s.ownerSearchText = "South"
            s.ownerSearchResults = SignUpUiState.mockOwners
            s.isOwnerPickerPresented = true
            return s
        }(),
        onEvent: { _ in }
    )
    .preferredColorScheme(.light)
}

#Preview("JoinShop - Tree Results - Dark") {
    JoinShopScreen(
        state: {
            var s = JoinShopUiState()
            s.ownerSearchText = "Nis"
            s.ownerSearchResults = SignUpUiState.mockOwners
            s.isOwnerPickerPresented = true
            return s
        }(),
        onEvent: { _ in }
    )
    .preferredColorScheme(.dark)
}

#Preview("JoinShop - Shop Selected - Light") {
    JoinShopScreen(
        state: {
            var s = JoinShopUiState()
            s.selectedOwner = SignUpUiState.mockOwners[0]
            s.selectedShop  = SignUpUiState.mockOwners[0].shops[0]
            return s
        }(),
        onEvent: { _ in }
    )
    .preferredColorScheme(.light)
}

#Preview("JoinShop - Request Sent - Dark") {
    JoinShopScreen(
        state: {
            var s = JoinShopUiState()
            s.selectedOwner = SignUpUiState.mockOwners[0]
            s.selectedShop  = SignUpUiState.mockOwners[0].shops[0]
            s.requestSent   = true
            return s
        }(),
        onEvent: { _ in }
    )
    .preferredColorScheme(.dark)
}

#Preview("JoinShop - Already Pending - Light") {
    JoinShopScreen(
        state: {
            var s = JoinShopUiState()
            s.pendingRequest = PendingShopRequest(
                requestID: "req-1", shopID: "shop-1", shopName: "South Lambeth Store"
            )
            return s
        }(),
        onEvent: { _ in }
    )
    .preferredColorScheme(.light)
}
