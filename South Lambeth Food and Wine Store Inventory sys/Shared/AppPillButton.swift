//
//  AppPillButton.swift
//  South Lambeth Food and Wine Store Inventory sys
//
//  Created by Mariyan Anjelo on 19/01/2026.
//
import SwiftUI

public struct AppPillButton: View {
    public let title: String
    public let isLoading: Bool
    public let isEnabled: Bool
    public let accessibilityLabel: String?
    public let action: () -> Void

    public init(
        title: String,
        isLoading: Bool = false,
        isEnabled: Bool = true,
        accessibilityLabel: String? = nil,
        action: @escaping () -> Void
    ) {
        self.title = title
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
                            .tint(AppTheme.Colors.buttonText)
                    }
                    
                    Text(title)
                        .font(AppTheme.Typography.button)
                        .foregroundStyle(AppTheme.Colors.buttonText)
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
        AppPillButton(title: "SEND TEST EMAIL") {}
        AppPillButton(title: "GET STARTED", isEnabled: true) {}
        AppPillButton(title: "Diabled", isEnabled: false) {}
    }
}

