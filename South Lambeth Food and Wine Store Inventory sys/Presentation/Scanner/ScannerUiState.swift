import Foundation

public struct ScannerUiState: Equatable {
    public var scannedCode: String? = nil
    public var isTorchOn: Bool = false
    public var permissionDenied: Bool = false
    public init() {}
}
