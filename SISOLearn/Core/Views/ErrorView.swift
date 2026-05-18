import SwiftUI

struct ErrorView: View {
    let error: AITutorError
    let retryAction: (() -> Void)?
    let settingsAction: (() -> Void)?

    init(error: AITutorError, retryAction: (() -> Void)? = nil, settingsAction: (() -> Void)? = nil) {
        self.error = error
        self.retryAction = retryAction
        self.settingsAction = settingsAction
    }

    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: iconName)
                .font(.system(size: 56)).foregroundColor(.orange)
            Text(error.errorDescription ?? "오류가 생겼어요")
                .font(.headline).multilineTextAlignment(.center)
            VStack(spacing: 12) {
                if let retry = retryAction, error.isRetryable {
                    Button("다시 시도") { retry() }
                        .buttonStyle(.borderedProminent).tint(.orange).frame(minHeight: 44)
                }
                if case .invalidAPIKey = error {
                    Button("API 키 설정하기") { settingsAction?() }
                        .buttonStyle(.bordered).frame(minHeight: 44)
                }
            }
        }
        .padding(32)
        .background(Color(.systemBackground)).cornerRadius(20)
        .shadow(color: .black.opacity(0.1), radius: 8)
        .padding()
    }

    private var iconName: String {
        switch error {
        case .offline, .networkError:  return "wifi.slash"
        case .rateLimitExceeded:       return "clock.badge.exclamationmark"
        case .dailyLimitExceeded:      return "moon.zzz.fill"
        case .invalidAPIKey:           return "key.slash"
        case .parseError:              return "exclamationmark.triangle"
        }
    }
}
