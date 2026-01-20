//
//  AppTheme.swift
//  South Lambeth Food and Wine Store Inventory sys
//
//  Created by Mariyan Anjelo on 18/01/2026.
//
import SwiftUI

// MARK : - App Theme (Single source for colors + spaceing  + typogtaphy

public enum AppTheme {
    // MARK: Colors
    public enum Colors {
        // Backgrounds
        public static func background(_ scheme: ColorScheme) -> Color {
            scheme == .dark ? Color(hex: 0x2B2B2B) : .white
        }

        // Text
        public static func primaryText(_ scheme: ColorScheme) -> Color {
            scheme == .dark ? .white : .black
        }

        public static func secondaryText(_ scheme: ColorScheme) -> Color {
            scheme == .dark
                ? Color.white.opacity(0.90) : Color.black.opacity(0.85)
        }

        // Accent / Brand
        // if Light: Purple, Dark = Yellow
        public static func accent(_ scheme: ColorScheme) -> Color {
            scheme == .dark ? Color(hex: 0xD6D000) : Color(hex: 0x6B57A7)
        }

        // Buttons
        public static let buttonText: Color = .black

        // for outlined fields / links
        public static func fieldBorder(_ scheme: ColorScheme) -> Color {
            // Subtle border that works in both schemes
            scheme == .dark
                ? Color.white.opacity(0.35) : Color.black.opacity(0.25)
        }

        public static func linkText(_ scheme: ColorScheme) -> Color {
            // Use brand accent for tappable text (your design: purple in light, yellow in dark)
            accent(scheme)
        }
    }

    // MARK: Typography
    public enum Typography {
        public static let welcomeHeadingLine = Font.system(
            size: 24,
            weight: .regular
        )
        public static let body = Font.system(size: 18, weight: .regular)
        public static let button = Font.system(size: 16, weight: .semibold)
        public static let title = Font.system(size: 22, weight: .semibold)
        public static let caption = Font.system(size: 14, weight: .medium)
        public static let fieldValue = Font.system(size: 18, weight: .semibold)
        public static let link = Font.system(size: 16, weight: .semibold)
    }

    // MARK: Layout
    public enum Layout {
        public static let screenHPadding: CGFloat = 24
        public static let topPadding: CGFloat = 24
        public static let bottomPadding: CGFloat = 18

        public static let pillHeight: CGFloat = 62
        public static let pillCornerRadious: CGFloat = 28

        public static let buttonSpacing: CGFloat = 16

        public static let fieldCornerRadius: CGFloat = 12
        public static let fieldBorderWidth: CGFloat = 1.2
        public static let fieldHorizonalPadding: CGFloat = 14
        public static let fieldVerticalPadding: CGFloat = 16
    }
}

// MARK: Helpers
extension Color {
    public init(hex: UInt, alpha: Double = 1.0) {
        let r = Double((hex >> 16) & 0xFF) / 255.0
        let g = Double((hex >> 8) & 0xFF) / 255.0
        let b = Double(hex & 0xFF) / 255.0

        self.init(.sRGB, red: r, green: g, blue: b, opacity: alpha)
    }
}
