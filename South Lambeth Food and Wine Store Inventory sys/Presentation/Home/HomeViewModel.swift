import Combine
//
//  HomeViewModel.swift
//  South Lambeth Food and Wine Store Inventory sys
//
//  Created by Mariyan Anjelo on 18/01/2026.
//
import Foundation
import SwiftUI

@MainActor
public final class HomeViewModel: ObservableObject {
    @Published public private(set) var state: HomeState
    @Published public private(set) var effect: HomeEffect?
    
    public init(initialState: HomeState) {
        self.state = initialState
    }
    public convenience init() {
        self.init(initialState: HomeState())
    }

    public func onEvent(_ event: HomeEvent) {
        switch event {
        case .onSignOutTapped:
            emit(.navigateWelcome)
        case .tabChanged(let tab):
            state.selectedTab = tab
        case .scanTapped:
            emit(.openScanner)
        }
    }

    private func emit(_ newEffect: HomeEffect) {
        effect = newEffect
        Task { @MainActor in
            await Task.yield()
            self.effect = nil
        }
    }
}

