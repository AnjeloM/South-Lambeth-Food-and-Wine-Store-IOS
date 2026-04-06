import Foundation

public enum SendResetMailUiEvent: Equatable {
    case onAppear
    case onbackTapped
    case emailChanged(String)
    case resendTapped
    
    // Timer-driven internal event
    case _tick
}
