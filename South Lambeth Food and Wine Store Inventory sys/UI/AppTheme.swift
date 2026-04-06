import SwiftUI

// MARK: - AppColorScheme
// Full Material 3 color token set. Equivalent to Compose's ColorScheme.
// Build one via the static factories below; inject it with .appTheme() modifier.

public struct AppColorScheme {
    public let primary:                   Color
    public let onPrimary:                 Color
    public let primaryContainer:          Color
    public let onPrimaryContainer:        Color

    public let secondary:                 Color
    public let onSecondary:               Color
    public let secondaryContainer:        Color
    public let onSecondaryContainer:      Color

    public let tertiary:                  Color
    public let onTertiary:                Color
    public let tertiaryContainer:         Color
    public let onTertiaryContainer:       Color

    public let error:                     Color
    public let onError:                   Color
    public let errorContainer:            Color
    public let onErrorContainer:          Color

    public let background:                Color
    public let onBackground:              Color

    public let surface:                   Color
    public let onSurface:                 Color
    public let surfaceVariant:            Color
    public let onSurfaceVariant:          Color

    public let outline:                   Color
    public let outlineVariant:            Color
    public let scrim:                     Color

    public let inverseSurface:            Color
    public let inverseOnSurface:          Color
    public let inversePrimary:            Color

    public let surfaceDim:                Color
    public let surfaceBright:             Color
    public let surfaceContainerLowest:    Color
    public let surfaceContainerLow:       Color
    public let surfaceContainer:          Color
    public let surfaceContainerHigh:      Color
    public let surfaceContainerHighest:   Color
}

// MARK: - Static Scheme Instances

public extension AppColorScheme {

    static let light = AppColorScheme(
        primary:                  primaryLight,
        onPrimary:                onPrimaryLight,
        primaryContainer:         primaryContainerLight,
        onPrimaryContainer:       onPrimaryContainerLight,
        secondary:                secondaryLight,
        onSecondary:              onSecondaryLight,
        secondaryContainer:       secondaryContainerLight,
        onSecondaryContainer:     onSecondaryContainerLight,
        tertiary:                 tertiaryLight,
        onTertiary:               onTertiaryLight,
        tertiaryContainer:        tertiaryContainerLight,
        onTertiaryContainer:      onTertiaryContainerLight,
        error:                    errorLight,
        onError:                  onErrorLight,
        errorContainer:           errorContainerLight,
        onErrorContainer:         onErrorContainerLight,
        background:               backgroundLight,
        onBackground:             onBackgroundLight,
        surface:                  surfaceLight,
        onSurface:                onSurfaceLight,
        surfaceVariant:           surfaceVariantLight,
        onSurfaceVariant:         onSurfaceVariantLight,
        outline:                  outlineLight,
        outlineVariant:           outlineVariantLight,
        scrim:                    scrimLight,
        inverseSurface:           inverseSurfaceLight,
        inverseOnSurface:         inverseOnSurfaceLight,
        inversePrimary:           inversePrimaryLight,
        surfaceDim:               surfaceDimLight,
        surfaceBright:            surfaceBrightLight,
        surfaceContainerLowest:   surfaceContainerLowestLight,
        surfaceContainerLow:      surfaceContainerLowLight,
        surfaceContainer:         surfaceContainerLight,
        surfaceContainerHigh:     surfaceContainerHighLight,
        surfaceContainerHighest:  surfaceContainerHighestLight
    )

    static let dark = AppColorScheme(
        primary:                  primaryDark,
        onPrimary:                onPrimaryDark,
        primaryContainer:         primaryContainerDark,
        onPrimaryContainer:       onPrimaryContainerDark,
        secondary:                secondaryDark,
        onSecondary:              onSecondaryDark,
        secondaryContainer:       secondaryContainerDark,
        onSecondaryContainer:     onSecondaryContainerDark,
        tertiary:                 tertiaryDark,
        onTertiary:               onTertiaryDark,
        tertiaryContainer:        tertiaryContainerDark,
        onTertiaryContainer:      onTertiaryContainerDark,
        error:                    errorDark,
        onError:                  onErrorDark,
        errorContainer:           errorContainerDark,
        onErrorContainer:         onErrorContainerDark,
        background:               backgroundDark,
        onBackground:             onBackgroundDark,
        surface:                  surfaceDark,
        onSurface:                onSurfaceDark,
        surfaceVariant:           surfaceVariantDark,
        onSurfaceVariant:         onSurfaceVariantDark,
        outline:                  outlineDark,
        outlineVariant:           outlineVariantDark,
        scrim:                    scrimDark,
        inverseSurface:           inverseSurfaceDark,
        inverseOnSurface:         inverseOnSurfaceDark,
        inversePrimary:           inversePrimaryDark,
        surfaceDim:               surfaceDimDark,
        surfaceBright:            surfaceBrightDark,
        surfaceContainerLowest:   surfaceContainerLowestDark,
        surfaceContainerLow:      surfaceContainerLowDark,
        surfaceContainer:         surfaceContainerDark,
        surfaceContainerHigh:     surfaceContainerHighDark,
        surfaceContainerHighest:  surfaceContainerHighestDark
    )

    static let lightMediumContrast = AppColorScheme(
        primary:                  primaryLightMC,
        onPrimary:                onPrimaryLightMC,
        primaryContainer:         primaryContainerLightMC,
        onPrimaryContainer:       onPrimaryContainerLightMC,
        secondary:                secondaryLightMC,
        onSecondary:              onSecondaryLightMC,
        secondaryContainer:       secondaryContainerLightMC,
        onSecondaryContainer:     onSecondaryContainerLightMC,
        tertiary:                 tertiaryLightMC,
        onTertiary:               onTertiaryLightMC,
        tertiaryContainer:        tertiaryContainerLightMC,
        onTertiaryContainer:      onTertiaryContainerLightMC,
        error:                    errorLightMC,
        onError:                  onErrorLightMC,
        errorContainer:           errorContainerLightMC,
        onErrorContainer:         onErrorContainerLightMC,
        background:               backgroundLightMC,
        onBackground:             onBackgroundLightMC,
        surface:                  surfaceLightMC,
        onSurface:                onSurfaceLightMC,
        surfaceVariant:           surfaceVariantLightMC,
        onSurfaceVariant:         onSurfaceVariantLightMC,
        outline:                  outlineLightMC,
        outlineVariant:           outlineVariantLightMC,
        scrim:                    scrimLight,
        inverseSurface:           inverseSurfaceLightMC,
        inverseOnSurface:         inverseOnSurfaceLightMC,
        inversePrimary:           inversePrimaryLightMC,
        surfaceDim:               surfaceDimLightMC,
        surfaceBright:            surfaceBrightLightMC,
        surfaceContainerLowest:   surfaceContainerLowestLightMC,
        surfaceContainerLow:      surfaceContainerLowLightMC,
        surfaceContainer:         surfaceContainerLightMC,
        surfaceContainerHigh:     surfaceContainerHighLightMC,
        surfaceContainerHighest:  surfaceContainerHighestLightMC
    )

    static let lightHighContrast = AppColorScheme(
        primary:                  primaryLightHC,
        onPrimary:                onPrimaryLightHC,
        primaryContainer:         primaryContainerLightHC,
        onPrimaryContainer:       onPrimaryContainerLightHC,
        secondary:                secondaryLightHC,
        onSecondary:              onSecondaryLightHC,
        secondaryContainer:       secondaryContainerLightHC,
        onSecondaryContainer:     onSecondaryContainerLightHC,
        tertiary:                 tertiaryLightHC,
        onTertiary:               onTertiaryLightHC,
        tertiaryContainer:        tertiaryContainerLightHC,
        onTertiaryContainer:      onTertiaryContainerLightHC,
        error:                    errorLightHC,
        onError:                  onErrorLightHC,
        errorContainer:           errorContainerLightHC,
        onErrorContainer:         onErrorContainerLightHC,
        background:               backgroundLightHC,
        onBackground:             onBackgroundLightHC,
        surface:                  surfaceLightHC,
        onSurface:                onSurfaceLightHC,
        surfaceVariant:           surfaceVariantLightHC,
        onSurfaceVariant:         onSurfaceVariantLightHC,
        outline:                  outlineLightHC,
        outlineVariant:           outlineVariantLightHC,
        scrim:                    scrimLight,
        inverseSurface:           inverseSurfaceLightHC,
        inverseOnSurface:         inverseOnSurfaceLightHC,
        inversePrimary:           inversePrimaryLightHC,
        surfaceDim:               surfaceDimLightHC,
        surfaceBright:            surfaceBrightLightHC,
        surfaceContainerLowest:   surfaceContainerLowestLightHC,
        surfaceContainerLow:      surfaceContainerLowLightHC,
        surfaceContainer:         surfaceContainerLightHC,
        surfaceContainerHigh:     surfaceContainerHighLightHC,
        surfaceContainerHighest:  surfaceContainerHighestLightHC
    )

    static let darkMediumContrast = AppColorScheme(
        primary:                  primaryDarkMC,
        onPrimary:                onPrimaryDarkMC,
        primaryContainer:         primaryContainerDarkMC,
        onPrimaryContainer:       onPrimaryContainerDarkMC,
        secondary:                secondaryDarkMC,
        onSecondary:              onSecondaryDarkMC,
        secondaryContainer:       secondaryContainerDarkMC,
        onSecondaryContainer:     onSecondaryContainerDarkMC,
        tertiary:                 tertiaryDarkMC,
        onTertiary:               onTertiaryDarkMC,
        tertiaryContainer:        tertiaryContainerDarkMC,
        onTertiaryContainer:      onTertiaryContainerDarkMC,
        error:                    errorDarkMC,
        onError:                  onErrorDarkMC,
        errorContainer:           errorContainerDarkMC,
        onErrorContainer:         onErrorContainerDarkMC,
        background:               backgroundDarkMC,
        onBackground:             onBackgroundDarkMC,
        surface:                  surfaceDarkMC,
        onSurface:                onSurfaceDarkMC,
        surfaceVariant:           surfaceVariantDarkMC,
        onSurfaceVariant:         onSurfaceVariantDarkMC,
        outline:                  outlineDarkMC,
        outlineVariant:           outlineVariantDarkMC,
        scrim:                    scrimDark,
        inverseSurface:           inverseSurfaceDarkMC,
        inverseOnSurface:         inverseOnSurfaceDarkMC,
        inversePrimary:           inversePrimaryDarkMC,
        surfaceDim:               surfaceDimDarkMC,
        surfaceBright:            surfaceBrightDarkMC,
        surfaceContainerLowest:   surfaceContainerLowestDarkMC,
        surfaceContainerLow:      surfaceContainerLowDarkMC,
        surfaceContainer:         surfaceContainerDarkMC,
        surfaceContainerHigh:     surfaceContainerHighDarkMC,
        surfaceContainerHighest:  surfaceContainerHighestDarkMC
    )

    static let darkHighContrast = AppColorScheme(
        primary:                  primaryDarkHC,
        onPrimary:                onPrimaryDarkHC,
        primaryContainer:         primaryContainerDarkHC,
        onPrimaryContainer:       onPrimaryContainerDarkHC,
        secondary:                secondaryDarkHC,
        onSecondary:              onSecondaryDarkHC,
        secondaryContainer:       secondaryContainerDarkHC,
        onSecondaryContainer:     onSecondaryContainerDarkHC,
        tertiary:                 tertiaryDarkHC,
        onTertiary:               onTertiaryDarkHC,
        tertiaryContainer:        tertiaryContainerDarkHC,
        onTertiaryContainer:      onTertiaryContainerDarkHC,
        error:                    errorDarkHC,
        onError:                  onErrorDarkHC,
        errorContainer:           errorContainerDarkHC,
        onErrorContainer:         onErrorContainerDarkHC,
        background:               backgroundDarkHC,
        onBackground:             onBackgroundDarkHC,
        surface:                  surfaceDarkHC,
        onSurface:                onSurfaceDarkHC,
        surfaceVariant:           surfaceVariantDarkHC,
        onSurfaceVariant:         onSurfaceVariantDarkHC,
        outline:                  outlineDarkHC,
        outlineVariant:           outlineVariantDarkHC,
        scrim:                    scrimDark,
        inverseSurface:           inverseSurfaceDarkHC,
        inverseOnSurface:         inverseOnSurfaceDarkHC,
        inversePrimary:           inversePrimaryDarkHC,
        surfaceDim:               surfaceDimDarkHC,
        surfaceBright:            surfaceBrightDarkHC,
        surfaceContainerLowest:   surfaceContainerLowestDarkHC,
        surfaceContainerLow:      surfaceContainerLowDarkHC,
        surfaceContainer:         surfaceContainerDarkHC,
        surfaceContainerHigh:     surfaceContainerHighDarkHC,
        surfaceContainerHighest:  surfaceContainerHighestDarkHC
    )

    // Resolves the correct scheme from SwiftUI environment values.
    // iOS maps contrast to .standard / .increased (no separate "medium" level).
    // We map .increased → highContrast to match the Android high-contrast accessibility path.
    static func resolve(colorScheme: ColorScheme, contrast: ColorSchemeContrast) -> AppColorScheme {
        switch (colorScheme, contrast) {
        case (.light,  .standard):  return .light
        case (.light,  .increased): return .lightHighContrast
        case (.dark,   .standard):  return .dark
        case (.dark,   .increased): return .darkHighContrast
        default:                    return colorScheme == .dark ? .dark : .light
        }
    }
}

// MARK: - Environment Key

private struct AppColorSchemeKey: EnvironmentKey {
    static let defaultValue: AppColorScheme = .light
}

public extension EnvironmentValues {
    var appColorScheme: AppColorScheme {
        get { self[AppColorSchemeKey.self] }
        set { self[AppColorSchemeKey.self] = newValue }
    }
}

// MARK: - View Modifier

/// Apply at the root of your view hierarchy (once, in AppRootView or the App entry point).
/// All descendant views can read `@Environment(\.appColorScheme)`.
///
/// ```swift
/// ContentView()
///     .appTheme()
/// ```
private struct AppThemeModifier: ViewModifier {
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.colorSchemeContrast) private var contrast

    func body(content: Content) -> some View {
        content
            .environment(
                \.appColorScheme,
                AppColorScheme.resolve(colorScheme: colorScheme, contrast: contrast)
            )
    }
}

public extension View {
    func appTheme() -> some View {
        modifier(AppThemeModifier())
    }
}

// MARK: - AppTheme

/// Convenience namespace for typography, layout constants, and
/// colour helpers that bridge the old API (`AppTheme.Colors.xxx(scheme)`).
///
/// For full Material 3 token access inside a View, use:
/// ```swift
/// @Environment(\.appColorScheme) private var colors
/// ```
public enum AppTheme {

    // MARK: Colors
    // Thin helpers over AppColorScheme — keep existing call sites working.
    public enum Colors {

        public static func background(_ scheme: ColorScheme) -> Color {
            scheme == .dark ? backgroundDark : backgroundLight
        }

        public static func surface(_ scheme: ColorScheme) -> Color {
            scheme == .dark ? surfaceDark : surfaceLight
        }

        public static func surfaceContainer(_ scheme: ColorScheme) -> Color {
            scheme == .dark ? surfaceContainerDark : surfaceContainerLight
        }

        public static func primaryText(_ scheme: ColorScheme) -> Color {
            scheme == .dark ? onBackgroundDark : onBackgroundLight
        }

        public static func secondaryText(_ scheme: ColorScheme) -> Color {
            scheme == .dark ? onSurfaceVariantDark : onSurfaceVariantLight
        }

        /// Brand accent — teal in light mode, light-blue in dark mode.
        public static func accent(_ scheme: ColorScheme) -> Color {
            scheme == .dark ? primaryDark : primaryLight
        }

        public static func primaryContainer(_ scheme: ColorScheme) -> Color {
            scheme == .dark ? primaryContainerDark : primaryContainerLight
        }

        public static func onPrimaryContainer(_ scheme: ColorScheme) -> Color {
            scheme == .dark ? onPrimaryContainerDark : onPrimaryContainerLight
        }

        public static func error(_ scheme: ColorScheme) -> Color {
            scheme == .dark ? errorDark : errorLight
        }

        public static func errorContainer(_ scheme: ColorScheme) -> Color {
            scheme == .dark ? errorContainerDark : errorContainerLight
        }

        public static func onErrorContainer(_ scheme: ColorScheme) -> Color {
            scheme == .dark ? onErrorContainerDark : onErrorContainerLight
        }

        public static func fieldBorder(_ scheme: ColorScheme) -> Color {
            scheme == .dark ? outlineDark : outlineLight
        }

        public static func fieldBorderVariant(_ scheme: ColorScheme) -> Color {
            scheme == .dark ? outlineVariantDark : outlineVariantLight
        }

        public static func linkText(_ scheme: ColorScheme) -> Color {
            accent(scheme)
        }

        public static func topBarShadowColor(_ scheme: ColorScheme) -> Color {
            scheme == .dark ? Color.black.opacity(0.45) : Color.black.opacity(0.12)
        }

        /// Light: white (on teal fill) — Dark: teal #00677C (the light-mode fill colour)
        public static func buttonText(_ scheme: ColorScheme) -> Color {
            scheme == .dark ? primaryLight : onPrimaryLight
        }
    }

    // MARK: Typography
    public enum Typography {
        public static let welcomeHeadingLine = Font.system(size: 24, weight: .regular)
        public static let body                = Font.system(size: 18, weight: .regular)
        public static let button              = Font.system(size: 16, weight: .semibold)
        public static let title               = Font.system(size: 22, weight: .semibold)
        public static let caption             = Font.system(size: 14, weight: .medium)
        public static let fieldValue          = Font.system(size: 18, weight: .semibold)
        public static let link                = Font.system(size: 16, weight: .semibold)
    }

    // MARK: Layout
    public enum Layout {
        public static let screenHPadding:      CGFloat = 24
        public static let topPadding:          CGFloat = 24
        public static let bottomPadding:       CGFloat = 18

        public static let pillHeight:          CGFloat = 62
        public static let pillCornerRadious:   CGFloat = 28

        public static let buttonSpacing:       CGFloat = 16

        public static let fieldCornerRadius:   CGFloat = 12
        public static let fieldBorderWidth:    CGFloat = 1.2
        public static let fieldHorizonalPadding: CGFloat = 14
        public static let fieldVerticalPadding:  CGFloat = 16
    }
}

// MARK: - Color hex init
public extension Color {
    init(hex: UInt, alpha: Double = 1.0) {
        let r = Double((hex >> 16) & 0xFF) / 255.0
        let g = Double((hex >> 8)  & 0xFF) / 255.0
        let b = Double( hex        & 0xFF) / 255.0
        self.init(.sRGB, red: r, green: g, blue: b, opacity: alpha)
    }
}

// MARK: - Previews

#Preview("Scheme tokens - Light") {
    let s = AppColorScheme.light
    return ScrollView {
        VStack(spacing: 0) {
            swatch("primary",          s.primary,          s.onPrimary)
            swatch("primaryContainer", s.primaryContainer, s.onPrimaryContainer)
            swatch("secondary",        s.secondary,        s.onSecondary)
            swatch("tertiary",         s.tertiary,         s.onTertiary)
            swatch("error",            s.error,            s.onError)
            swatch("background",       s.background,       s.onBackground)
            swatch("surface",          s.surface,          s.onSurface)
            swatch("surfaceVariant",   s.surfaceVariant,   s.onSurfaceVariant)
        }
    }
    .preferredColorScheme(.light)
}

#Preview("Scheme tokens - Dark") {
    let s = AppColorScheme.dark
    return ScrollView {
        VStack(spacing: 0) {
            swatch("primary",          s.primary,          s.onPrimary)
            swatch("primaryContainer", s.primaryContainer, s.onPrimaryContainer)
            swatch("secondary",        s.secondary,        s.onSecondary)
            swatch("tertiary",         s.tertiary,         s.onTertiary)
            swatch("error",            s.error,            s.onError)
            swatch("background",       s.background,       s.onBackground)
            swatch("surface",          s.surface,          s.onSurface)
            swatch("surfaceVariant",   s.surfaceVariant,   s.onSurfaceVariant)
        }
    }
    .preferredColorScheme(.dark)
}

private func swatch(_ name: String, _ bg: Color, _ fg: Color) -> some View {
    Text(name)
        .font(.system(size: 13, weight: .medium))
        .foregroundStyle(fg)
        .frame(maxWidth: .infinity, minHeight: 44)
        .background(bg)
}
