//
//  HomeScreen.swift
//  South Lambeth Food and Wine Store Inventory sys
//
//  Created by Mariyan Anjelo on 18/01/2026.
//
import SwiftUI

public struct HomeScreen: View {
    public let state: HomeState
    public let onEvent: (HomeEvent) -> Void

    public init(state: HomeState, onEvent: @escaping (HomeEvent) -> Void) {
        self.state = state
        self.onEvent = onEvent
    }

    public var body: some View {
        VStack(spacing: 14) {
            Spacer()

            Text(state.title)
                .font(.system(size: 30, weight: .heavy))

            Text(state.subTitle)
                .font(.system(size: 16))
                .foregroundStyle(.secondary)

            Button(state.signOutButtonText) {
                onEvent(.onSignOutTapped)
            }
            .buttonStyle(.bordered)
            .padding(.top, 10)

            Spacer()
        }
        .padding(24)
        .navigationBarBackButtonHidden(true)
    }
}

struct HomeScreen_Previews: PreviewProvider {
    static var previews: some View {
        HomeScreen(state: HomeState(), onEvent: { _ in })
    }
}
