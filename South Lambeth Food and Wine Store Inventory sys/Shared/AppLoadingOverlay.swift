import SwiftUI

/// Full-screen blocking overlay shown during async operations that precede navigation.
/// Prevents all user interaction while visible.
struct AppLoadingOverlay: View {
    @Environment(\.colorScheme) private var scheme

    var body: some View {
        ZStack {
            Color.black.opacity(0.45)
                .ignoresSafeArea()

            ProgressView()
                .progressViewStyle(.circular)
                .tint(AppTheme.Colors.accent(scheme))
                .scaleEffect(1.4)
        }
        .allowsHitTesting(true)
    }
}

#Preview("AppLoadingOverlay - Light") {
    ZStack {
        Color.white.ignoresSafeArea()
        AppLoadingOverlay()
    }
    .preferredColorScheme(.light)
}

#Preview("AppLoadingOverlay - Dark") {
    ZStack {
        Color.black.ignoresSafeArea()
        AppLoadingOverlay()
    }
    .preferredColorScheme(.dark)
}
