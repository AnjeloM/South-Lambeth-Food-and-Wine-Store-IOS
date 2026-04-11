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

    // MARK: Init

    public init(
        initialState: HomeState = HomeState(),
        printOrderRepository: PrintOrderRepositoring = LocalPrintOrderRepository()
    ) {
        self.state = initialState
        self.printOrderRepository = printOrderRepository
        Task { @MainActor in loadDefaultPrintList() }
    }

    // MARK: - Event Handler

    public func onEvent(_ event: HomeEvent) {
        switch event {
        case .onSignOutTapped:
            emit(.navigateWelcome)
        case .tabChanged(let tab):
            state.selectedTab = tab
        case .scanTapped:
            emit(.openScanner)
        case .openSetPrintOrder:
            emit(.openSetPrintOrder)
        case .openManageShop:
            emit(.openManageShop)
        case .onSetPrintOrderClosed:
            loadDefaultPrintList()
        }
    }

    // MARK: - Private Helpers

    private func loadDefaultPrintList() {
        let storage = printOrderRepository.load()
        state.defaultPrintList = storage.defaultList
    }

    private func emit(_ newEffect: HomeEffect) {
        effect = newEffect
        Task { @MainActor in
            await Task.yield()
            self.effect = nil
        }
    }
}

