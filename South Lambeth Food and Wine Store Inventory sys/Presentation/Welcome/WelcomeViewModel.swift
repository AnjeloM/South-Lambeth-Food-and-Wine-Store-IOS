//
//  WelcomeViewModel.swift
//  South Lambeth Food and Wine Store Inventory sys
//
//  Created by Mariyan Anjelo on 18/01/2026.
//
import Foundation
import Combine
import SwiftUI

@MainActor
// 
public final class WelcomeViewModel: ObservableObject {
    @Published public private(set) var state: WelcomeUiState
    
    private let testEmailSender: TestEmailSending
    private let effectSubject = PassthroughSubject<WelcomeUiEffect, Never>()
    
    public var effects: AnyPublisher<WelcomeUiEffect, Never> {
        effectSubject.eraseToAnyPublisher()
    }

    public init(
        initialState: WelcomeUiState,
        testEmailSender: TestEmailSending,
    ) {
        self.state = initialState
        self.testEmailSender = testEmailSender
    }

    public convenience init() {
        self.init(
            initialState: WelcomeUiState(),
            testEmailSender: DemoTestEmailSender()
        )
    }

    public func onEvent(_ event: WelcomeUiEvent) {
        switch event {
        case .sendTestEmailTapped:
            sendTestEmail()
        case .getStartedTapped:
            emit(.navigateToSignIn)
        }
    }

    private func emit(_ effect: WelcomeUiEffect) {
        effectSubject.send(effect)
    }
    
    private func sendTestEmail() {
        guard !state.isSendingTestEmail else {return}
        
        state.isSendingTestEmail = true
        
        Task {
            do {
                try await testEmailSender.sendTestEmail()
                state.isSendingTestEmail = false
                effectSubject.send(.showToast(message: "Test email sent successfully"))
            } catch {
                state.isSendingTestEmail = false
                effectSubject.send(.showToast(message: "Failed to send test email. Please try again."))
            }
        }
    }
}



