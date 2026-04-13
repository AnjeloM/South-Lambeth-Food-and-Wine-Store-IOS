//
//  HomeViewModel.swift
//  South Lambeth Food and Wine Store Inventory sys
//
//  Created by Mariyan Anjelo on 18/01/2026.
//
import Combine
import Foundation
import SwiftUI

@MainActor
public final class HomeViewModel: ObservableObject {
    @Published public private(set) var state: HomeState
    @Published public private(set) var effect: HomeEffect?

    // MARK: Dependencies

    private let printOrderRepository: PrintOrderRepositoring
    private let profileFetcher: UserProfileFetching
    private let notificationReader: OwnerNotificationReading

    // MARK: Init

    public init(
        initialState: HomeState = HomeState(),
        printOrderRepository: PrintOrderRepositoring = LocalPrintOrderRepository(),
        profileFetcher: UserProfileFetching = FirebaseUserProfileFetcher(),
        notificationReader: OwnerNotificationReading = FirebaseEmployeeRequestCenter()
    ) {
        self.state = initialState
        self.printOrderRepository = printOrderRepository
        self.profileFetcher = profileFetcher
        self.notificationReader = notificationReader
        Task { @MainActor in
            loadDefaultPrintList()
            await loadDrawerProfile()
            await loadUnreadNotification()
        }
    }

    // MARK: - Event Handler

    public func onEvent(_ event: HomeEvent) {
        switch event {
        case .onAppear:
            Task {
                await loadDrawerProfile()
                await loadUnreadNotification()
            }
        case .onSignOutTapped:
            emit(.navigateWelcome)
        case .tabChanged(let tab):
            state.selectedTab = tab
        case .scanTapped:
            emit(.openScanner)
        case .openSetPrintOrder:
            emit(.openSetPrintOrder)
        case .openManageShop:
            emit(.openManageShop(highlightRequestID: nil))
        case .notificationTapped:
            Task { await openUnreadNotification() }
        case .onSetPrintOrderClosed:
            loadDefaultPrintList()
        case .onManageShopClosed:
            Task {
                await loadDrawerProfile()
                await loadUnreadNotification()
            }
        }
    }

    // MARK: - Private Helpers

    private func loadDefaultPrintList() {
        let storage = printOrderRepository.load()
        state.defaultPrintList = storage.defaultList
    }

    private func loadDrawerProfile() async {
        do {
            state.drawerProfile = try await profileFetcher.fetchProfile()
        } catch {
            // Profile is non-critical — drawer falls back to placeholder text on failure
        }
    }

    private func loadUnreadNotification() async {
        do {
            state.unreadNotification = try await notificationReader.latestUnreadRequestNotification()
        } catch {
            state.unreadNotification = nil
        }
    }

    private func openUnreadNotification() async {
        guard let unread = state.unreadNotification else { return }

        do {
            try await notificationReader.markNotificationRead(id: unread.id)
        } catch {
            // Keep navigation working even if the read-state update fails.
        }
        state.unreadNotification = nil
        emit(.openManageShop(highlightRequestID: unread.requestID))
    }

    private func emit(_ newEffect: HomeEffect) {
        effect = newEffect
        Task { @MainActor in
            await Task.yield()
            self.effect = nil
        }
    }
}
