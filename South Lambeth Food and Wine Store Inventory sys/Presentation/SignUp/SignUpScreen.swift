import SwiftUI

public struct SignUpScreen: View {
    public let state: SignUpUiState
    public let onEvent: (SignUpUiEvent) -> Void

    public init(
        state: SignUpUiState,
        onEvent: @escaping (SignUpUiEvent) -> Void
    ) {
        self.state = state
        self.onEvent = onEvent
    }

    @Environment(\.colorScheme) private var scheme

    private enum Field: Hashable {
        case name, email, password, retypePassword
    }

    @FocusState private var focusedField: Field?

    // MARK: - Sheet bindings

    private var ownerSheetBinding: Binding<Bool> {
        Binding(
            get: { state.isOwnerPickerPresented },
            set: { if !$0 { onEvent(.ownerPickerDismissed) } }
        )
    }

    private var shopSheetBinding: Binding<Bool> {
        Binding(
            get: { state.isShopPickerPresented },
            set: { if !$0 { onEvent(.shopPickerDismissed) } }
        )
    }

    public var body: some View {
        ZStack {
            AppTheme.Colors.background(scheme)
                .ignoresSafeArea()

            VStack(alignment: .leading, spacing: 0) {
                AppTopBar(
                    title:  state.title,
                    showBack: true,
                    showsShadow: true
                ) {
                    onEvent(.onbackTapped)
                }

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 12) {

                        // MARK: Account fields
                        OutlinedTextField(
                            title: state.nameLabel,
                            text: Binding(
                                get: { state.name },
                                set: { onEvent(.nameChanged($0)) }
                            ),
                            keyboard: .default,
                            textContentType: .name,
                            autocapitalization: .words
                        )
                        .focused($focusedField, equals: .name)
                        .submitLabel(.next)
                        .onSubmit { focusedField = .email }

                        VStack(alignment: .leading, spacing: 4) {
                            OutlinedTextField(
                                title: state.emailLabel,
                                text: Binding(
                                    get: { state.email },
                                    set: { onEvent(.emailChanged($0)) }
                                ),
                                keyboard: .emailAddress,
                                textContentType: .emailAddress,
                                autocapitalization: .never
                            )
                            .focused($focusedField, equals: .email)
                            .submitLabel(.next)
                            .onSubmit { focusedField = .password }

                            if let emailError = state.emailError {
                                Text(emailError)
                                    .font(.caption)
                                    .foregroundStyle(AppTheme.Colors.error(scheme))
                                    .padding(.horizontal, 4)
                            }
                        }

                        OutlinedPasswordField(
                            title: state.passwordLabel,
                            text: Binding(
                                get: { state.password },
                                set: { onEvent(.passwordChanged($0)) }
                            ),
                            isVisible: state.isPasswordVisible,
                            onToggleVisibility: {
                                onEvent(.togglePasswordVisibility)
                            }
                        )
                        .focused($focusedField, equals: .password)
                        .submitLabel(.next)
                        .onSubmit { focusedField = .retypePassword }

                        OutlinedPasswordField(
                            title: state.retypePasswordLabel,
                            text: Binding(
                                get: { state.retypePassword },
                                set: { onEvent(.retypePasswordChanged($0)) }
                            ),
                            isVisible: state.isRetypePasswordVisible,
                            onToggleVisibility: {
                                onEvent(.toggleRetypePasswordVisibility)
                            }
                        )
                        .focused($focusedField, equals: .retypePassword)
                        .submitLabel(.done)
                        .onSubmit {
                            focusedField = nil
                        }

                        passwordRules

                        // MARK: Store Assignment
                        storeAssignmentSection
                            .padding(.top, 8)
                    }

                    Spacer(minLength: 0)

                    VStack(spacing: 12) {
                        Spacer(minLength: 24)
                        AppPillButton(
                            title: state.signUpButtonText,
                            isLoading: state.isLoading,
                            isEnabled: !state.isLoading
                        ) {
                            onEvent(.signUpTapped)
                        }

                        // AppPillButton(
                        //     title: state.googleButtonText,
                        //     icon: .custom(AnyView(GoogleGlyph()))
                        // ) {
                        //     onEvent(.googleTapped)
                        // }

                        // orDivider

                        // AppPillButton(
                        //     title: state.appleButtonText,
                        //     icon: .system("apple.logo")
                        // ) {
                        //     onEvent(.appleTapped)
                        // }
                    }

                    footer
                        .padding(.top, 12)
                }
                .padding(.horizontal, 18)
                .padding(.top, 10)
                .padding(.bottom, 18)
                .onAppear { onEvent(.onAppear) }
            }
            .scrollDismissesKeyboard(.interactively)
            .simultaneousGesture(
                TapGesture().onEnded {
                    focusedField = nil
                }
            )
            .toolbar {
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button("Done") {
                        focusedField = nil
                    }
                }
            }
        }
        // MARK: Owner picker sheet
        .sheet(isPresented: ownerSheetBinding) {
            OwnerPickerSheet(
                owners: state.availableOwners,
                selectedOwner: state.selectedOwner,
                onSelect: { onEvent(.ownerSelected($0)) },
                onDismiss: { onEvent(.ownerPickerDismissed) }
            )
            .presentationDetents([.medium, .large])
            .presentationDragIndicator(.hidden)
        }
        // MARK: Shop picker sheet
        .sheet(isPresented: shopSheetBinding) {
            ShopPickerSheet(
                shops: state.selectedOwner?.shops ?? [],
                selectedShop: state.selectedShop,
                onSelect: { onEvent(.shopSelected($0)) },
                onDismiss: { onEvent(.shopPickerDismissed) }
            )
            .presentationDetents([.medium, .large])
            .presentationDragIndicator(.hidden)
        }
    }

    // MARK: - Store Assignment Section

    private var storeAssignmentSection: some View {
        VStack(alignment: .leading, spacing: 12) {

            // Section header
            HStack(spacing: 8) {
                Image(systemName: "storefront.fill")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(AppTheme.Colors.accent(scheme))
                Text("Store Assignment")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(AppTheme.Colors.primaryText(scheme))
            }

            Text("Select the owner you work for and choose your default shop. Your account will be sent for owner approval after verification.")
                .font(.system(size: 12))
                .foregroundStyle(AppTheme.Colors.secondaryText(scheme))
                .fixedSize(horizontal: false, vertical: true)

            // Owner picker row
            pickerRow(
                label: "Shop Owner",
                icon: "person.crop.circle.fill",
                placeholder: "Select a shop owner",
                value: state.selectedOwner.map { "\($0.name) — \($0.storeName)" },
                isEnabled: true,
                showClearButton: state.selectedOwner != nil,
                onClear: { onEvent(.clearOwnerSelection) },
                onTap: { onEvent(.ownerPickerTapped) }
            )

            // Shop picker row (disabled until owner is selected)
            pickerRow(
                label: "Default Shop",
                icon: "storefront.fill",
                placeholder: state.selectedOwner == nil
                    ? "Select an owner first"
                    : "Select your default shop",
                value: state.selectedShop.map { "\($0.name)" },
                isEnabled: state.selectedOwner != nil,
                showClearButton: false,
                onClear: {},
                onTap: { onEvent(.shopPickerTapped) }
            )
        }
        .padding(16)
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
    private func pickerRow(
        label: String,
        icon: String,
        placeholder: String,
        value: String?,
        isEnabled: Bool,
        showClearButton: Bool,
        onClear: @escaping () -> Void,
        onTap: @escaping () -> Void
    ) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(label)
                .font(AppTheme.Typography.caption)
                .foregroundStyle(AppTheme.Colors.secondaryText(scheme))

            Button(action: onTap) {
                HStack(spacing: 10) {
                    Image(systemName: icon)
                        .font(.system(size: 15))
                        .foregroundStyle(
                            isEnabled
                                ? AppTheme.Colors.accent(scheme)
                                : AppTheme.Colors.secondaryText(scheme)
                        )
                        .frame(width: 22)

                    if let value {
                        Text(value)
                            .font(AppTheme.Typography.fieldValue)
                            .foregroundStyle(AppTheme.Colors.primaryText(scheme))
                            .lineLimit(1)
                    } else {
                        Text(placeholder)
                            .font(AppTheme.Typography.fieldValue)
                            .foregroundStyle(AppTheme.Colors.secondaryText(scheme))
                    }

                    Spacer()

                    if showClearButton {
                        Button(action: onClear) {
                            Image(systemName: "xmark.circle.fill")
                                .font(.system(size: 16))
                                .foregroundStyle(AppTheme.Colors.secondaryText(scheme))
                        }
                        .buttonStyle(.plain)
                    } else {
                        Image(systemName: "chevron.down")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundStyle(
                                isEnabled
                                    ? AppTheme.Colors.secondaryText(scheme)
                                    : AppTheme.Colors.secondaryText(scheme).opacity(0.4)
                            )
                    }
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 14)
                .background(
                    RoundedRectangle(cornerRadius: AppTheme.Layout.fieldCornerRadius, style: .continuous)
                        .strokeBorder(
                            AppTheme.Colors.fieldBorder(scheme),
                            lineWidth: AppTheme.Layout.fieldBorderWidth
                        )
                )
                .opacity(isEnabled ? 1 : 0.5)
            }
            .buttonStyle(.plain)
            .disabled(!isEnabled)
        }
    }

    // MARK: - Password Rules

    private var passwordRules: some View {
        VStack(alignment: .leading, spacing: 8) {
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
        .padding(.top, 4)
        .padding(.bottom, 8)
    }

    // MARK: orDivider
    private var orDivider: some View {
        HStack(spacing: 12) {
            Rectangle()
                .fill(AppTheme.Colors.fieldBorder(scheme))
                .frame(height: 1)

            Text("OR")
                .font(.footnote.weight(.semibold))
                .foregroundStyle(AppTheme.Colors.secondaryText(scheme))

            Rectangle()
                .fill(AppTheme.Colors.fieldBorder(scheme))
                .frame(height: 1)
        }
        .padding(.horizontal, 8)
    }

    // MARK: Footer
    private var footer: some View {
        VStack(spacing: 6) {
            Text(state.footerPrefixText)
                .font(.footnote)
                .foregroundStyle(AppTheme.Colors.secondaryText(scheme))

            VStack(spacing: 4) {
                Text("\(state.footerBrandText)'s")
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(AppTheme.Colors.accent(scheme))

                HStack(spacing: 6) {
                    Button(state.privacyPolicyText) {
                        onEvent(.privacyPolicyTapped)
                    }
                    .buttonStyle(.plain)
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(AppTheme.Colors.accent(scheme))
                    .underline()

                    Text(state.andText)
                        .font(.footnote)
                        .foregroundStyle(AppTheme.Colors.secondaryText(scheme))

                    Button(state.termsText) { onEvent(.termsTapped) }
                        .buttonStyle(.plain)
                        .font(.footnote.weight(.semibold))
                        .foregroundStyle(AppTheme.Colors.accent(scheme))
                        .underline()
                }
            }
            .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .multilineTextAlignment(.center)
    }
}

// MARK: - OwnerPickerSheet

private struct OwnerPickerSheet: View {

    let owners: [SignUpOwner]
    let selectedOwner: SignUpOwner?
    let onSelect: (SignUpOwner) -> Void
    let onDismiss: () -> Void

    @Environment(\.colorScheme) private var scheme
    @State private var searchText = ""
    @FocusState private var isSearchFocused: Bool

    /// Only owners with at least one shop are eligible for selection.
    private var eligibleOwners: [SignUpOwner] {
        owners.filter { !$0.shops.isEmpty }
    }

    private var filteredOwners: [SignUpOwner] {
        let q = searchText.trimmingCharacters(in: .whitespaces)
        guard !q.isEmpty else { return eligibleOwners }
        return eligibleOwners.filter {
            $0.name.localizedCaseInsensitiveContains(q) ||
            $0.storeName.localizedCaseInsensitiveContains(q)
        }
    }

    var body: some View {
        VStack(spacing: 0) {

            // Drag handle
            Capsule()
                .fill(AppTheme.Colors.fieldBorderVariant(scheme))
                .frame(width: 36, height: 4)
                .padding(.top, 12)
                .padding(.bottom, 14)

            Text("Select Shop Owner")
                .font(.system(size: 17, weight: .semibold))
                .foregroundStyle(AppTheme.Colors.primaryText(scheme))
                .padding(.bottom, 4)

            Text("Choose the owner you work for")
                .font(.system(size: 13))
                .foregroundStyle(AppTheme.Colors.secondaryText(scheme))
                .padding(.bottom, 14)

            Divider()

            // MARK: Search bar
            HStack(spacing: 8) {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(AppTheme.Colors.secondaryText(scheme))

                TextField("Search by owner or store name…", text: $searchText)
                    .font(AppTheme.Typography.fieldValue)
                    .autocorrectionDisabled(true)
                    .textInputAutocapitalization(.never)
                    .focused($isSearchFocused)

                if !searchText.isEmpty {
                    Button {
                        searchText = ""
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 15))
                            .foregroundStyle(AppTheme.Colors.secondaryText(scheme))
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 11)
            .background(
                RoundedRectangle(cornerRadius: AppTheme.Layout.fieldCornerRadius, style: .continuous)
                    .fill(AppTheme.Colors.surfaceContainer(scheme))
            )
            .padding(.horizontal, AppTheme.Layout.screenHPadding)
            .padding(.vertical, 12)

            Divider()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 10) {
                    if filteredOwners.isEmpty {
                        ownerEmptyState
                    } else {
                        ForEach(filteredOwners) { owner in
                            ownerRow(owner)
                        }
                    }
                }
                .padding(.horizontal, AppTheme.Layout.screenHPadding)
                .padding(.vertical, 14)
            }

            Divider()

            Button(action: onDismiss) {
                Text("Cancel")
                    .font(AppTheme.Typography.button)
                    .foregroundStyle(AppTheme.Colors.primaryText(scheme))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(
                        RoundedRectangle(cornerRadius: AppTheme.Layout.pillCornerRadious, style: .continuous)
                            .fill(AppTheme.Colors.surfaceContainer(scheme))
                    )
            }
            .buttonStyle(.plain)
            .padding(.horizontal, AppTheme.Layout.screenHPadding)
            .padding(.top, 14)
            .padding(.bottom, 32)
        }
        .background(AppTheme.Colors.background(scheme))
    }

    private var ownerEmptyState: some View {
        let hasQuery = !searchText.trimmingCharacters(in: .whitespaces).isEmpty
        return VStack(spacing: 10) {
            Image(systemName: hasQuery ? "person.slash" : "storefront.slash")
                .font(.system(size: 28))
                .foregroundStyle(AppTheme.Colors.secondaryText(scheme))
            Text(
                hasQuery
                    ? "No owners found for \"\(searchText.trimmingCharacters(in: .whitespaces))\""
                    : "No owners available yet"
            )
            .font(AppTheme.Typography.caption)
            .foregroundStyle(AppTheme.Colors.secondaryText(scheme))
            .multilineTextAlignment(.center)
            if !hasQuery {
                Text("Owners must have at least one registered shop before staff can sign up under them.")
                    .font(.system(size: 12))
                    .foregroundStyle(AppTheme.Colors.secondaryText(scheme))
                    .multilineTextAlignment(.center)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 36)
    }

    @ViewBuilder
    private func ownerRow(_ owner: SignUpOwner) -> some View {
        let isSelected = selectedOwner?.id == owner.id

        Button { onSelect(owner) } label: {
            HStack(spacing: 14) {
                ZStack {
                    Circle()
                        .fill(isSelected
                              ? AppTheme.Colors.accent(scheme)
                              : AppTheme.Colors.primaryContainer(scheme))
                        .frame(width: 44, height: 44)
                    Image(systemName: "person.fill")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundStyle(isSelected
                                         ? AppTheme.Colors.buttonText(scheme)
                                         : AppTheme.Colors.onPrimaryContainer(scheme))
                }

                VStack(alignment: .leading, spacing: 3) {
                    Text(owner.name)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(AppTheme.Colors.primaryText(scheme))
                    Text(owner.storeName)
                        .font(.system(size: 12))
                        .foregroundStyle(AppTheme.Colors.secondaryText(scheme))
                    Text("\(owner.shops.count) shop\(owner.shops.count == 1 ? "" : "s")")
                        .font(.system(size: 11))
                        .foregroundStyle(AppTheme.Colors.secondaryText(scheme))
                }

                Spacer()

                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 20))
                        .foregroundStyle(AppTheme.Colors.accent(scheme))
                }
            }
            .padding(14)
            .background(
                RoundedRectangle(cornerRadius: AppTheme.Layout.fieldCornerRadius, style: .continuous)
                    .fill(AppTheme.Colors.surfaceContainer(scheme))
            )
            .overlay(
                RoundedRectangle(cornerRadius: AppTheme.Layout.fieldCornerRadius, style: .continuous)
                    .strokeBorder(
                        isSelected ? AppTheme.Colors.accent(scheme) : Color.clear,
                        lineWidth: 2
                    )
            )
            .animation(.easeInOut(duration: 0.15), value: isSelected)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - ShopPickerSheet

private struct ShopPickerSheet: View {

    let shops: [SignUpShop]
    let selectedShop: SignUpShop?
    let onSelect: (SignUpShop) -> Void
    let onDismiss: () -> Void

    @Environment(\.colorScheme) private var scheme

    var body: some View {
        VStack(spacing: 0) {

            // Drag handle
            Capsule()
                .fill(AppTheme.Colors.fieldBorderVariant(scheme))
                .frame(width: 36, height: 4)
                .padding(.top, 12)
                .padding(.bottom, 14)

            Text("Select Default Shop")
                .font(.system(size: 17, weight: .semibold))
                .foregroundStyle(AppTheme.Colors.primaryText(scheme))
                .padding(.bottom, 4)

            Text("This will be your default working location")
                .font(.system(size: 13))
                .foregroundStyle(AppTheme.Colors.secondaryText(scheme))
                .padding(.bottom, 14)

            Divider()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 10) {
                    ForEach(shops) { shop in
                        shopRow(shop)
                    }
                }
                .padding(.horizontal, AppTheme.Layout.screenHPadding)
                .padding(.vertical, 14)
            }

            Divider()

            Button(action: onDismiss) {
                Text("Cancel")
                    .font(AppTheme.Typography.button)
                    .foregroundStyle(AppTheme.Colors.primaryText(scheme))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(
                        RoundedRectangle(cornerRadius: AppTheme.Layout.pillCornerRadious, style: .continuous)
                            .fill(AppTheme.Colors.surfaceContainer(scheme))
                    )
            }
            .buttonStyle(.plain)
            .padding(.horizontal, AppTheme.Layout.screenHPadding)
            .padding(.top, 14)
            .padding(.bottom, 32)
        }
        .background(AppTheme.Colors.background(scheme))
    }

    @ViewBuilder
    private func shopRow(_ shop: SignUpShop) -> some View {
        let isSelected = selectedShop?.id == shop.id

        Button { onSelect(shop) } label: {
            HStack(spacing: 14) {
                ZStack {
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .fill(isSelected
                              ? AppTheme.Colors.accent(scheme)
                              : AppTheme.Colors.primaryContainer(scheme))
                        .frame(width: 44, height: 44)
                    Image(systemName: "storefront.fill")
                        .font(.system(size: 17, weight: .medium))
                        .foregroundStyle(isSelected
                                         ? AppTheme.Colors.buttonText(scheme)
                                         : AppTheme.Colors.onPrimaryContainer(scheme))
                }

                VStack(alignment: .leading, spacing: 3) {
                    Text(shop.name)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(AppTheme.Colors.primaryText(scheme))
                    Text(shop.address)
                        .font(.system(size: 12))
                        .foregroundStyle(AppTheme.Colors.secondaryText(scheme))
                        .lineLimit(1)
                }

                Spacer()

                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 20))
                        .foregroundStyle(AppTheme.Colors.accent(scheme))
                }
            }
            .padding(14)
            .background(
                RoundedRectangle(cornerRadius: AppTheme.Layout.fieldCornerRadius, style: .continuous)
                    .fill(AppTheme.Colors.surfaceContainer(scheme))
            )
            .overlay(
                RoundedRectangle(cornerRadius: AppTheme.Layout.fieldCornerRadius, style: .continuous)
                    .strokeBorder(
                        isSelected ? AppTheme.Colors.accent(scheme) : Color.clear,
                        lineWidth: 2
                    )
            )
            .animation(.easeInOut(duration: 0.15), value: isSelected)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Google glyph (temporary; replace later with real logo asset)

private struct GoogleGlyph: View {
    var body: some View {
        ZStack {
            Circle()
                .fill(Color.black.opacity(0.12))
                .frame(width: 30, height: 30)

            Text("G")
                .font(.system(size: 16, weight: .black))
                .foregroundStyle(.black)
        }
        .accessibilityHidden(true)
    }
}

// MARK: - Previews

#Preview("SignUp - Empty") {
    SignUpScreen(state: SignUpUiState(), onEvent: { _ in })
        .preferredColorScheme(.light)
}

#Preview("SignUp - Dark") {
    SignUpScreen(state: SignUpUiState(), onEvent: { _ in })
        .preferredColorScheme(.dark)
}

#Preview("SignUp - Owner Selected") {
    let state: SignUpUiState = {
        var s = SignUpUiState()
        s.name  = "Anjelo"
        s.email = "anjelo@example.com"
        s.selectedOwner = SignUpUiState.mockOwners[0]
        s.selectedShop  = SignUpUiState.mockOwners[0].shops[0]
        return s
    }()
    SignUpScreen(state: state, onEvent: { _ in })
        .preferredColorScheme(.light)
}

#Preview("Owner Picker Sheet") {
    OwnerPickerSheet(
        owners: SignUpUiState.mockOwners,
        selectedOwner: SignUpUiState.mockOwners[0],
        onSelect: { _ in },
        onDismiss: {}
    )
    .preferredColorScheme(.light)
}

#Preview("Shop Picker Sheet") {
    ShopPickerSheet(
        shops: SignUpUiState.mockOwners[0].shops,
        selectedShop: SignUpUiState.mockOwners[0].shops[0],
        onSelect: { _ in },
        onDismiss: {}
    )
    .preferredColorScheme(.light)
}
