//
//  GateRouteHostView.swift
//  South Lambeth Food and Wine Store Inventory sys
//
//  Created by Mariyan Anjelo on 17/01/2026.
//

import SwiftUI

@MainActor
public struct GateRouteHostView: View {
    @StateObject private var viewModel: GateViewModel

    private let onNavigate: (GateRoute) -> Void

    public init(
        sessionChecker: SessionChecking,
        onNavigate: @escaping (GateRoute) -> Void
    ) {
        _viewModel = StateObject(
            wrappedValue: GateViewModel(sessionChecker: sessionChecker)
        )
        self.onNavigate = onNavigate
    }

    public var body: some View {
        GateScreen(
            state: viewModel.state,
            onEvent: viewModel.onEvent
        )
        .onChange(of: viewModel.effect) { oldEffect, newEffect in
            guard let newEffect else { return }
            switch newEffect {
            case .navigate(let route):
                onNavigate(route)
            }
        }
    }
}

#Preview("GateRouteHostView - Light") {
    GateRouteHostView(sessionChecker: DemoSessionChecker(signedIn: false)) {_ in}
        .preferredColorScheme(.light)
}

#Preview("GateRouteHostView - Dark") {
    GateRouteHostView(sessionChecker: DemoSessionChecker(signedIn: true)) {_ in }
        .preferredColorScheme(.dark)
}
