//
//  AppPillButton.swift
//  South Lambeth Food and Wine Store Inventory sys
//
//  Created by Mariyan Anjelo on 19/01/2026.
//
import SwiftUI

public enum AppPillButtonIcon: Equatable {
    case system(String) // SF Symbol, e.g "apple.logo"
    case custom(AnyView) // Any SwiftUi view, e.g GoogleGlyph()
    
    
    public static func == (lhs: AppPillButtonIcon, rhs: AppPillButtonIcon) -> Bool {
        switch (lhs, rhs) {
        case (.system(let a), .system(let b)) :
            return a == b
        case (.custom, .custom):
            // AnyView is not Equatable; treat as equal for UI purposes
            return true
        default:
            return false
        }
    }
}

public struct AppPillButton: View {
    public let title: String
    public let icon: AppPillButtonIcon?
    public let isLoading: Bool
    public let isEnabled: Bool
    public let accessibilityLabel: String?
    public let action: () -> Void

    public init(
        title: String,
        icon: AppPillButtonIcon? = nil,
        isLoading: Bool = false,
        isEnabled: Bool = true,
        accessibilityLabel: String? = nil,
        action: @escaping () -> Void
    ) {
        self.title = title
        self.icon = icon
        self.isLoading = isLoading
        self.isEnabled = isEnabled
        self.accessibilityLabel = accessibilityLabel
        self.action = action
    }

    @Environment(\.colorScheme) private var scheme

    public var body: some View {
        Button(action: action) {
            ZStack {
                RoundedRectangle(
                    cornerRadius: AppTheme.Layout.pillCornerRadious,
                    style: .continuous
                )
                .fill(AppTheme.Colors.accent(scheme))
                .opacity(isEnabled ? 1.0 : 0.55)
                .frame(height: AppTheme.Layout.pillHeight)

                HStack(spacing: 10) {
                    if isLoading {
                        ProgressView()
                            .tint(AppTheme.Colors.buttonText(scheme))
                    }

                    if let icon = icon {
                        switch icon {
                        case .system(let name):
                            Image(systemName: name)
                                .foregroundStyle(AppTheme.Colors.buttonText(scheme))
                        case .custom(let view):
                            view
                        }
                    }

                    Text(title)
                        .font(AppTheme.Typography.button)
                        .foregroundStyle(AppTheme.Colors.buttonText(scheme))
                        .tracking(0.8)
                }
            }
        }
        .buttonStyle(.plain)
        .disabled(!isEnabled || isLoading)
        .accessibilityLabel(accessibilityLabel ?? title)
    }
}
#Preview("AppPillButton") {
    VStack(spacing: 16) {
        AppPillButton(title: "GET STARTED") {}
        AppPillButton(title: "Continue with Apple", icon: .system("apple.logo")) {}
        AppPillButton(title: "Continue with Google", icon: .custom(AnyView(GoogleGlyphPreview()))) {}
        AppPillButton(title: "Loading", isLoading: true) {}
        AppPillButton(title: "Disabled", isEnabled: false) {}
    }
    .padding()
}

private struct GoogleGlyphPreview: View {
    var body: some View {
        ZStack {
            Circle()
                .fill(Color.black.opacity(0.12))
                .frame(width: 30, height: 30)
            Text("G")
                .font(.system(size: 16, weight: .black))
                .foregroundStyle(.black)
        }
    }
}
