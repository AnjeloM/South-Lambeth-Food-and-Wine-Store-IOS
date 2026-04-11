//
//  TopBar.swift
//  South Lambeth Food and Wine Store Inventory sys
//
//  Created by Mariyan Anjelo on 21/01/2026.
//

import SwiftUI

// MARK: Top Bar
public struct AppTopBar: View {
    public let title: String
    public let showBack: Bool
    public let onBack: () -> Void
    public let showsShadow: Bool
    /// Optional view placed in the trailing slot. When nil a transparent spacer keeps the title centred.
    public let trailingContent: AnyView?

    public init(
        title: String,
        showBack: Bool = true,
        showsShadow: Bool = true,
        trailingContent: AnyView? = nil,
        onBack: @escaping () -> Void
    ) {
        self.title = title
        self.showBack = showBack
        self.showsShadow = showsShadow
        self.trailingContent = trailingContent
        self.onBack = onBack
    }

    @Environment(\.colorScheme) private var scheme

    public var body: some View {

        HStack(spacing: 12) {
            if showBack {
                Button(action: onBack) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(AppTheme.Colors.primaryText(scheme))
                        .frame(width: 44, height: 44)
                }
                .buttonStyle(.plain)
            } else {
                // Keep title centered when there is no back button
                Color.clear.frame(width: 44, height: 44)
            }

            Spacer()

            Text(title)
                .font(.system(size: 22, weight: .semibold))
                .foregroundStyle(AppTheme.Colors.primaryText(scheme))

            Spacer()

            if let trailing = trailingContent {
                trailing
            } else {
                Color.clear.frame(width: 44, height: 44)
            }
        }
        .padding(.top, 2)
        .padding(.bottom, 8)
        .padding(.horizontal, 18)
        .background(AppTheme.Colors.background(scheme))
        .shadow(
            color: showsShadow
                ? AppTheme.Colors.topBarShadowColor(scheme) : .clear,
            radius: showsShadow ? 8 : 0,
            x: 0,
            y: showsShadow ? 6 : 0
        )
        .zIndex(1)
    }
}

#Preview("AppTopBar - Light") {
    VStack(spacing: 0) {
        AppTopBar(title: "SignUp", showsShadow: true) {}
        Spacer()
    }
    .preferredColorScheme(.light)
}

#Preview("AppTopBar - Dark") {
    VStack(spacing: 0) {
        AppTopBar(title: "SignUp", showsShadow: true) {}
        Spacer()
    }
    .preferredColorScheme(.dark)
}
