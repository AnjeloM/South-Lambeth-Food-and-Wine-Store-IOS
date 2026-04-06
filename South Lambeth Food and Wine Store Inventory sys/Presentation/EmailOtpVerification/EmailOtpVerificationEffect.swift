import Foundation

public enum EmailOtpVerificationEffect: Equatable {
    case navigateBack
    case verifiedSuccessfully
    case showToast(String)
}
