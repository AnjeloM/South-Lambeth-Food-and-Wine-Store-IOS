//
//  HomeRouteHostView.swift
//  South Lambeth Food and Wine Store Inventory sys
//
//  Created by Mariyan Anjelo on 18/01/2026.
//
import SwiftUI

public struct HomeRouteHostView: View {
    @StateObject private var viewModel = HomeViewModel()
    private let onNavigateWelcome: () -> Void
    
    public init(onNavigateWelcome: @escaping () -> Void) {
        self.onNavigateWelcome = onNavigateWelcome
    }
    
    public var body: some View {
        HomeScreen(state: viewModel.state, onEvent: viewModel.onEvent)
            .onChange(of: viewModel.effect) { oldEffect, newEffect in
                guard let newEffect else { return }
                switch newEffect {
                case .navigateWelcome:
                    onNavigateWelcome()
                }
            }
    }
}

