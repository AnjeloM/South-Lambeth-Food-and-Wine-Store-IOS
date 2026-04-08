import SwiftUI

// MARK: - AppScreenHeader
//
// Design reference: Components/head.png
// Layout: [ProfilePic] ─── [Title (accent)] ─── [Bell + badge] [Drawer ≡]
//
// Usage:
//   AppScreenHeader(title: "Inventory", onNotificationTapped: { }, onDrawerTapped: { })

public struct AppScreenHeader: View {

    public let title: String
    public var hasUnreadNotification: Bool
    public let onNotificationTapped: () -> Void
    public let onDrawerTapped: () -> Void

    public init(
        title: String,
        hasUnreadNotification: Bool = true,
        onNotificationTapped: @escaping () -> Void = {},
        onDrawerTapped: @escaping () -> Void = {}
    ) {
        self.title = title
        self.hasUnreadNotification = hasUnreadNotification
        self.onNotificationTapped = onNotificationTapped
        self.onDrawerTapped = onDrawerTapped
    }

    @Environment(\.colorScheme) private var scheme

    public var body: some View {
        HStack(spacing: 0) {

            // MARK: Profile Picture
            profileAvatar

            Spacer()

            // MARK: Page Title
            Text(title)
                .font(.system(size: 17, weight: .semibold))
                .foregroundStyle(AppTheme.Colors.accent(scheme))
                .lineLimit(1)

            Spacer()

            // MARK: Right actions — Bell + Drawer
            HStack(spacing: 10) {
                notificationBell
                drawerButton
            }
        }
        .padding(.horizontal, AppTheme.Layout.screenHPadding)
        .padding(.vertical, 12)
        .background(AppTheme.Colors.background(scheme))
    }

    // MARK: - Sub-views

    @ViewBuilder
    private var profileAvatar: some View {
        Image("ProfilePic")
            .resizable()
            .scaledToFill()
            .frame(width: 42, height: 42)
            .clipShape(Circle())
            .overlay(Circle().strokeBorder(AppTheme.Colors.fieldBorderVariant(scheme), lineWidth: 1))
    }

    @ViewBuilder
    private var notificationBell: some View {
        Button(action: onNotificationTapped) {
            ZStack(alignment: .topTrailing) {
                Image(systemName: "bell.fill")
                    .font(.system(size: 18))
                    .foregroundStyle(AppTheme.Colors.primaryText(scheme))
                    .frame(width: 40, height: 40)
                    .background(Circle().fill(AppTheme.Colors.surfaceContainer(scheme)))

                if hasUnreadNotification {
                    Circle()
                        .fill(AppTheme.Colors.accent(scheme))
                        .frame(width: 9, height: 9)
                        .offset(x: 1, y: -1)
                }
            }
        }
        .buttonStyle(.plain)
    }

    @ViewBuilder
    private var drawerButton: some View {
        Button(action: onDrawerTapped) {
            Image(systemName: "line.3.horizontal")
                .font(.system(size: 18, weight: .medium))
                .foregroundStyle(AppTheme.Colors.primaryText(scheme))
                .frame(width: 40, height: 40)
                .background(Circle().fill(AppTheme.Colors.surfaceContainer(scheme)))
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Previews

#Preview("AppScreenHeader - Light") {
    VStack(spacing: 0) {
        AppScreenHeader(title: "Soft Drinks", hasUnreadNotification: true)
        Spacer()
    }
    .preferredColorScheme(.light)
}

#Preview("AppScreenHeader - Dark") {
    VStack(spacing: 0) {
        AppScreenHeader(title: "Inventory", hasUnreadNotification: false)
        Spacer()
    }
    .preferredColorScheme(.dark)
}
