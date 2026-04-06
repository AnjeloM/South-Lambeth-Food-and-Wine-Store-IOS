import Foundation
import Combine

@MainActor
public final class ScannerViewModel: ObservableObject {

    @Published public private(set) var state: ScannerUiState

    public let effects: AsyncStream<ScannerUiEffect>
    private let effectContinuation: AsyncStream<ScannerUiEffect>.Continuation

    // Prevent repeated haptics/updates for the same barcode value
    private var lastDetectedCode: String? = nil

    public init(initialState: ScannerUiState? = nil) {
        self.state = initialState ?? ScannerUiState()

        var cont: AsyncStream<ScannerUiEffect>.Continuation!
        self.effects = AsyncStream(bufferingPolicy: .bufferingNewest(10)) { cont = $0 }
        self.effectContinuation = cont
    }

    deinit {
        effectContinuation.finish()
    }

    public func send(_ event: ScannerUiEvent) {
        switch event {

        case .onAppear:
            break

        case .closeTapped:
            emit(.close)

        case .torchToggled:
            state.isTorchOn.toggle()

        case .barcodeDetected(let code):
            // Only update + haptic if it's a new value
            guard code != lastDetectedCode else { return }
            lastDetectedCode = code
            state.scannedCode = code
            emit(.triggerHaptic)

        case .permissionDenied:
            state.permissionDenied = true
        }
    }

    // MARK: - Private

    private func emit(_ effect: ScannerUiEffect) {
        effectContinuation.yield(effect)
    }
}
