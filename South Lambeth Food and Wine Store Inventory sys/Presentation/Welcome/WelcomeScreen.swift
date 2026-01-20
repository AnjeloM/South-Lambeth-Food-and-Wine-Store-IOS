//
//  Untitled.swift
//  South Lambeth Food and Wine Store Inventory sys
//
//  Created by Mariyan Anjelo on 18/01/2026.
//
import SwiftUI

public struct WelcomeScreen: View {
    public let state: WelcomeUiState
    public let onEvent: (WelcomeUiEvent) -> Void

    public init(
        state: WelcomeUiState,
        onEvent: @escaping (WelcomeUiEvent) -> Void,
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
                Text(state.headlineText)
                    .font(AppTheme.Typography.welcomeHeadingLine)
                    .foregroundStyle(AppTheme.Colors.primaryText(scheme))
                    .multilineTextAlignment(.leading)
                    .lineSpacing(6)
                    .padding(.top, AppTheme.Layout.topPadding)
                    .padding(.horizontal, AppTheme.Layout.screenHPadding)

                Spacer(minLength: 24)

                VStack(spacing: AppTheme.Layout.buttonSpacing) {
                    AppPillButton(
                        title: state.sendTestEmaitButtonTitle,
                        isLoading: state.isSendingTestEmail,
                        isEnabled: !state.isSendingTestEmail,
                        action: { onEvent(.sendTestEmailTapped) }
                    )
                    AppPillButton(
                        title: state.getStartedButtonTitle,
                        isLoading: false,
                        isEnabled: !state.isSendingTestEmail,
                        action: {onEvent(.getStartedTapped)}
                    )
                }
                .padding(.horizontal, AppTheme.Layout.screenHPadding)
                .padding(.bottom, AppTheme.Layout.bottomPadding)
            }
        }
    }

    private var brandDescription: some View {
        let hightlight = AppTheme.Colors.primaryText(scheme)
        let body = AppTheme.Colors.secondaryText(scheme)

        var attributed = AttributedString("")

        // Highlight 1
        var part1 = AttributedString(state.brandHighlight1)
        part1.foregroundColor = Color(hightlight)
        part1.inlinePresentationIntent = .emphasized
        attributed += part1

        // Normal 2
        var part2 = AttributedString(state.brandNormal2)
        part2.foregroundColor = Color(body)
        attributed += part2

        // Highlight 2
        var part3 = AttributedString(state.brandHighlight2)
        part3.foregroundColor = Color(hightlight)
        part3.inlinePresentationIntent = .emphasized
        attributed += part3

        // Normal 3
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
}
