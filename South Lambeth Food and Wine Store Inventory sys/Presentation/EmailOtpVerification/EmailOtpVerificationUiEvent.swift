import Foundation

public enum EmailOtpVerificationUiEvent: Equatable {
    case onAppear
    case backTapped

    case otpChanged(index: Int, value: String)
    case verifyTapped
    case resendTapped
}
