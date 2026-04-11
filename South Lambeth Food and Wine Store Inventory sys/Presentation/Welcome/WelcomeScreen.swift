import SwiftUI

public struct WelcomeScreen: View {
    public let state: WelcomeUiState
    public let onEvent: (WelcomeUiEvent) -> Void

    public init(
        state: WelcomeUiState,
        onEvent: @escaping (WelcomeUiEvent) -> Void
    ) {
        self.state = state
        self.onEvent = onEvent
    }

    @Environment(\.colorScheme) private var scheme

    public var body: some View {
        ZStack {
            AppTheme.Colors.background(scheme)
                .ignoresSafeArea()

            VStack(alignment: .leading, spacing: 0) {
                VStack(alignment: .leading, spacing: 12) {
                    Text(state.headlineText)
                        .font(AppTheme.Typography.welcomeHeadingLine)
                        .foregroundStyle(AppTheme.Colors.primaryText(scheme))
                        .multilineTextAlignment(.leading)
                        .lineSpacing(6)
                        .padding(.top, AppTheme.Layout.topPadding)

                    Spacer().frame(height: 8)

                    brandDescription
                }
                .padding(.horizontal, AppTheme.Layout.screenHPadding)
                .padding(.bottom, 16)

                Spacer()

                AppPillButton(
                    title: state.getStartedButtonTitle,
                    isLoading: false,
                    isEnabled: true,
                    action: { onEvent(.getStartedTapped) }
                )
                .padding(.horizontal, AppTheme.Layout.screenHPadding)
                .padding(.bottom, AppTheme.Layout.screenHPadding)
            }
        }
    }

    private var brandDescription: some View {
        let highlight = AppTheme.Colors.primaryText(scheme)
        let body = AppTheme.Colors.secondaryText(scheme)

        var attributed = AttributedString("")

        var part1 = AttributedString(state.brandHighlight1)
        part1.foregroundColor = Color(highlight)
        part1.inlinePresentationIntent = .emphasized
        attributed += part1

        var part2 = AttributedString(state.brandNormal2)
        part2.foregroundColor = Color(body)
        attributed += part2

        var part3 = AttributedString(state.brandHighlight2)
        part3.foregroundColor = Color(highlight)
        part3.inlinePresentationIntent = .emphasized
        attributed += part3

        var part4 = AttributedString(state.brandNormal3)
        part4.foregroundColor = Color(body)
        attributed += part4

        return Text(attributed)
            .font(AppTheme.Typography.body)
            .lineSpacing(6)
            .multilineTextAlignment(.leading)
    }
}

#Preview("WelcomeScreen - Light") {
    WelcomeScreen(state: WelcomeUiState(), onEvent: { _ in })
        .preferredColorScheme(.light)
}

#Preview("WelcomeScreen - Dark") {
    WelcomeScreen(state: WelcomeUiState(), onEvent: { _ in })
        .preferredColorScheme(.dark)
}
