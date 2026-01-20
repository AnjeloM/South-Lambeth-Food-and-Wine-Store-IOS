import Combine
//
//  GateViewModel.swift
//  South Lambeth Food and Wine Store Inventory sys
//
//  Created by Mariyan Anjelo on 17/01/2026.
//
import Foundation
import SwiftUI

@MainActor
public final class GateViewModel: ObservableObject {
    @Published public private(set) var state: GateState
    @Published public private(set) var effect: GateEffect?

    private let sessionChecker: SessionChecking

    public init(
        initialState: GateState,
        sessionChecker: SessionChecking
    ) {
        self.state = initialState
        self.sessionChecker = sessionChecker
    }
    
    public convenience init(sessionChecker: SessionChecking) {
        self.init(initialState: GateState(), sessionChecker: sessionChecker)
    }

    public func onEvent(_ event: GateEvent) {
        switch event {
        case .onAppear:
            handleOnAppear()

        case .routeResolved(let route):
            emit(.navigate(route))
        }
    }

    private func handleOnAppear() {
        // Prevent duplicate calls if the view re-appears
        guard !state.isLoading else { return }
        state.isLoading = true

        Task {
            // Keeps splash visible briefly for polish.
            try? await Task.sleep(nanoseconds: 2_000_000_000) // 2 seconds

            let signedIn = await sessionChecker.isSignedIn()
            let route: GateRoute = signedIn ? .home : .welcome

            onEvent(.routeResolved(route))
        }
    }

    private func emit(_ neweffect: GateEffect) {
        effect = neweffect

        // Clear one-off effect so it doesn't reply
        Task { @MainActor in
            await Task.yield()
            self.effect = nil
        }
    }
}

