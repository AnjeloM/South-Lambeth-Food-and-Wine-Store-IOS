import Foundation

public struct WelcomeUiState: Equatable {
    public var headlineText: String = "Want to get store inventory? An app that makes your inventory process faster and easier"

    // Brand paragraph parts (to highlight specific words)
    public var brandHighlight1: String = "SOUTH LAMBETH"
    public var brandNormal2: String = " FOOD & WINE "
    public var brandHighlight2: String = "STORE"
    public var brandNormal3: String = " Inventory App will help you add items to your inventory by scanning the barcode or searching by name with fast and easy steps, and export a final PDF format that can be printed easily."

    public var getStartedButtonTitle: String = "GET STARTED"

    public init() {}
}
