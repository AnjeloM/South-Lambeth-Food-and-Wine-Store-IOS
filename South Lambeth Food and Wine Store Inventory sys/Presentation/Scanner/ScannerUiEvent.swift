import Foundation

public enum ScannerUiEvent {
    case onAppear
    case closeTapped
    case torchToggled
    case barcodeDetected(String)
    case permissionDenied
}
