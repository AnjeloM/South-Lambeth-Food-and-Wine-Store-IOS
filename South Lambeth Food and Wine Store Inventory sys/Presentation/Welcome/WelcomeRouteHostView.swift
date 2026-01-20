
//
//  WelcomeRouteHostView.swift
//  South Lambeth Food and Wine Store Inventory sys
//
//  Created by Mariyan Anjelo on 18/01/2026.
//
import SwiftUI
import Combine

public enum WelcomeRoute: Equatable {
    case signIn
}

public struct WelcomeRouteHostView: View {
    @StateObject private var viewModel: WelcomeViewModel


    private let onNavigate: (WelcomeRoute) -> Void

    // Toast/alert state(one-off UI)
    @State private var toastMessage: String?
    @State private var isToastPresended: Bool = false

    public init(
        onNavigate: @escaping (WelcomeRoute) -> Void
    ) {
        _viewModel = StateObject(wrappedValue: WelcomeViewModel())
        self.onNavigate = onNavigate
    }

    public init(
        initialState: WelcomeUiState = WelcomeUiState(),
        testEmailSender: TestEmailSending,
        onNavigate: @escaping (WelcomeRoute) -> Void
    ) {
        self._viewModel = StateObject(
            wrappedValue: WelcomeViewModel(
                initialState: initialState,
                testEmailSender: testEmailSender
            )
        )
        self.onNavigate = onNavigate
    }

    public var body: some View {
        WelcomeScreen(
            state: viewModel.state,
            onEvent: viewModel.onEvent
        )
        .onReceive(viewModel.effects) { effect in
            handel(effect)
        }
        .alert("Info", isPresented: $isToastPresended) {
            Button("Ok", role: .cancel) {}
        } message: {
            Text(toastMessage ?? "")
        }
    }
    
    private func handel(_ effect: WelcomeUiEffect) {
        switch effect{
        case .navigateToSignIn:
            onNavigate(.signIn)
        case .showToast(let message):
            toastMessage = message
            isToastPresended = true
        }
    }
}

#Preview("WelcomeRouteHostView - Light") {
    WelcomeRouteHostView(
        initialState: WelcomeUiState(),
        testEmailSender: DemoTestEmailSender(),
        onNavigate: { _ in }
    )
    .preferredColorScheme(.light)
}

#Preview("WelcomeRouteHostView - Dark") {
    WelcomeRouteHostView(
        initialState: WelcomeUiState(),
        testEmailSender: DemoTestEmailSender(),
        onNavigate: { _ in }
    )
    .preferredColorScheme(.dark)
}
