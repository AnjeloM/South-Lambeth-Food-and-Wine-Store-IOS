import Combine
import Foundation

@MainActor
public final class EmailOtpVerificationViewModel: ObservableObject {
    @Published public private(set) var state: EmailOtpVerificationUiState

    public let effect: AsyncStream<EmailOtpVerificationEffect>
    private let effectContinuation:
        AsyncStream<EmailOtpVerificationEffect>.Continuation

    private let service: EmailOtpServicing
    private var cooldownTask: Task<Void, Never>?

    // Cooldown steps: 60s, 2m, 5, 30, 1h
    private let cooldownPresents: [Int] = [60, 120, 300, 1800, 3600]

    public init(
        email: String,
        service: EmailOtpServicing,
        initialState: EmailOtpVerificationUiState? = nil
    ) {
        self.service = service
        self.state = initialState ?? EmailOtpVerificationUiState(email: email)

        var continuation: AsyncStream<EmailOtpVerificationEffect>.Continuation!
        self.effect = AsyncStream(bufferingPolicy: .bufferingNewest(10)) { continuationIn in
            continuation = continuationIn
        }
        self.effectContinuation = continuation
    }

    deinit {
        cooldownTask?.cancel()
        effectContinuation.finish()
    }
}
