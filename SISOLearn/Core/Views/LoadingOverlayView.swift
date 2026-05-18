import SwiftUI

struct LoadingOverlayView: View {
    let message: String

    var body: some View {
        ZStack {
            Color.black.opacity(0.3).ignoresSafeArea()
            VStack(spacing: 16) {
                Text("🐶").font(.system(size: 48))
                ProgressView().scaleEffect(1.2).tint(AppTheme.primary)
                Text(message).font(AppTheme.bodyFont).foregroundColor(.primary)
            }
            .padding(32)
            .background(Color(.systemBackground).opacity(0.95))
            .cornerRadius(20)
            .shadow(radius: 10)
        }
    }
}
