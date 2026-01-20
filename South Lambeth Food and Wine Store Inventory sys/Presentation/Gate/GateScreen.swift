//
//  GateScreen.swift
//  South Lambeth Food and Wine Store Inventory sys
//
//  Created by Mariyan Anjelo on 17/01/2026.
//

import SwiftUI

public struct GateScreen: View {
    public let state: GateState
    public let onEvent: (GateEvent) -> Void

    @Environment(\.colorScheme) private var colorScheme

    public init(
        state: GateState,
        onEvent: @escaping (GateEvent) -> Void
    ) {
        self.state = state
        self.onEvent = onEvent
    }

    public var body: some View {
        ZStack {
            background

            VStack(spacing: 18) {
                Spacer()

                brandBlock

                if state.isLoading {
                    ProgressView()
                        .progressViewStyle(.circular)
                        .scaleEffect(1.05)
                        .padding(.top, 10)
                }

                Spacer()
            }
            .padding(.horizontal, 24)
        }
        .ignoresSafeArea()
        .onAppear { onEvent(.onAppear) }
    }

    private var background: Color {
        colorScheme == .dark ? .black : .white
    }
    private var primaryText: Color {
        colorScheme == .dark ? .white : .black
    }

    private var highlight: Color {
        if colorScheme == .dark {
            return Color(red: 0.95, green: 0.83, blue: 0.12)  // BrandYellow
        } else {
            return Color(red: 0.41, green: 0.36, blue: 0.75)  // BrandPurple
        }
    }

    // MARK: - UI
    private var brandBlock: some View {
        VStack(spacing: 6) {
            highlightedWordLine(
                fullText: state.titleTop,
                highlightIndices: Set([0, 6])
            )
            .font(.system(size: 28, weight: .heavy))

            Text(state.titleMiddle)
                .font(.system(size: 26, weight: .bold))
                .foregroundStyle(primaryText)

            Text(state.titlteStore)
                .font(.system(size: 30, weight: .heavy))
                .foregroundStyle(highlight)

            Text(state.subtitile)
                .font(.system(size: 14))
                .italic()
                .foregroundStyle(primaryText.opacity(0.55))
                .padding(.top, 2)
        }
        .multilineTextAlignment(.center)
        .accessibilityElement(children: .combine)
    }

    private func highlightedWordLine(
        fullText: String,
        highlightIndices: Set<Int>
    ) -> some View {
        HStack(spacing: 0) {
            ForEach(Array(fullText.enumerated()), id: \.offset) { index, char in
                Text(String(char))
                    .foregroundStyle(
                        highlightIndices.contains(index)
                            ? highlight : primaryText
                    )
            }
        }
    }
}

struct GateScreen_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            GateScreen(state: GateState(), onEvent: {_ in})
                .preferredColorScheme(.light)
            GateScreen(state: GateState(), onEvent: {_ in})
                .preferredColorScheme(.dark)
        }
    }
}
