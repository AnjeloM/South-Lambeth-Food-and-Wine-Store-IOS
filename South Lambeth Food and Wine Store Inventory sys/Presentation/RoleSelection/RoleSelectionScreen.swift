import SwiftUI

// MARK: - RoleSelectionScreen
//
// Pure view — renders RoleSelectionUiState, emits RoleSelectionUiEvent.
// Zero business logic, zero ViewModel reference.

public struct RoleSelectionScreen: View {

    public let state: RoleSelectionUiState
    public let onEvent: (RoleSelectionUiEvent) -> Void

    public init(
        state: RoleSelectionUiState,
        onEvent: @escaping (RoleSelectionUiEvent) -> Void
    ) {
        self.state = state
        self.onEvent = onEvent
    }

    @Environment(\.colorScheme) private var scheme

    // MARK: - Body

    public var body: some View {
        ZStack {
            AppTheme.Colors.background(scheme)
                .ignoresSafeArea()

            VStack(spacing: 0) {
                AppTopBar(
                    title: state.title,
                    showBack: true,
                    showsShadow: true
                ) {
                    onEvent(.backTapped)
                }

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 32) {
                        headerText
                            .padding(.top, 32)

                        VStack(spacing: 16) {
                            roleCard(
                                icon: state.userRoleIcon,
                                title: state.userRoleTitle,
                                description: state.userRoleDescription
                            ) {
                                onEvent(.userRoleTapped)
                            }

                            roleCard(
                                icon: state.ownerRoleIcon,
                                title: state.ownerRoleTitle,
                                description: state.ownerRoleDescription
                            ) {
                                onEvent(.ownerRoleTapped)
                            }
                        }
                    }
                    .padding(.horizontal, AppTheme.Layout.screenHPadding)
                    .padding(.bottom, 32)
                }
            }
        }
    }

    // MARK: - Header

    private var headerText: some View {
        VStack(spacing: 8) {
            Text("Who are you?")
                .font(.system(size: 26, weight: .bold))
                .foregroundStyle(AppTheme.Colors.primaryText(scheme))

            Text("Choose your account type to get started")
                .font(AppTheme.Typography.body)
                .foregroundStyle(AppTheme.Colors.secondaryText(scheme))
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Role Card

    @ViewBuilder
    private func roleCard(
        icon: String,
        title: String,
        description: String,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            HStack(spacing: 16) {

                // Icon circle
                ZStack {
                    Circle()
                        .fill(AppTheme.Colors.accent(scheme))
                        .frame(width: 52, height: 52)
                    Image(systemName: icon)
                        .font(.system(size: 22, weight: .semibold))
                        .foregroundStyle(AppTheme.Colors.buttonText(scheme))
                }

                // Text block
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(AppTheme.Colors.primaryText(scheme))

                    Text(description)
                        .font(AppTheme.Typography.caption)
                        .foregroundStyle(AppTheme.Colors.secondaryText(scheme))
                        .multilineTextAlignment(.leading)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer(minLength: 8)

                // Trailing chevron
                Image(systemName: "chevron.right")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(AppTheme.Colors.secondaryText(scheme))
            }
            .padding(18)
            .background(
                RoundedRectangle(cornerRadius: AppTheme.Layout.fieldCornerRadius, style: .continuous)
                    .fill(AppTheme.Colors.surfaceContainer(scheme))
            )
            .overlay(
                RoundedRectangle(cornerRadius: AppTheme.Layout.fieldCornerRadius, style: .continuous)
                    .strokeBorder(AppTheme.Colors.fieldBorderVariant(scheme), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Previews

#Preview("RoleSelection - Light") {
    RoleSelectionScreen(
        state: RoleSelectionUiState(),
        onEvent: { _ in }
    )
    .preferredColorScheme(.light)
}

#Preview("RoleSelection - Dark") {
    RoleSelectionScreen(
        state: RoleSelectionUiState(),
        onEvent: { _ in }
    )
    .preferredColorScheme(.dark)
}
