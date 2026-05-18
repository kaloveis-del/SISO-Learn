import SwiftUI

struct CookieBubbleView: View {
    var cookieVM: CookieViewModel

    var body: some View {
        HStack(alignment: .bottom, spacing: 12) {
            ZStack {
                Circle().fill(Color.orange.opacity(0.15)).frame(width: 72, height: 72)
                Text(cookieVM.currentEmotion.emoji).font(.system(size: 40))
            }
            .scaleEffect(cookieVM.isTyping ? 1.05 : 1.0)
            .animation(.easeInOut(duration: 0.6).repeatForever(autoreverses: true), value: cookieVM.isTyping)

            if cookieVM.isTyping {
                HStack(spacing: 4) {
                    ForEach(0..<3) { i in
                        Circle().fill(Color.orange).frame(width: 8, height: 8)
                            .scaleEffect(cookieVM.isTyping ? 1.2 : 0.8)
                            .animation(.easeInOut(duration: 0.4).repeatForever().delay(Double(i) * 0.15), value: cookieVM.isTyping)
                    }
                }
                .padding(.horizontal, 16).padding(.vertical, 12)
                .background(RoundedRectangle(cornerRadius: 18).fill(Color(.systemBackground)).shadow(color: .black.opacity(0.08), radius: 4))
            } else if !cookieVM.currentMessage.isEmpty {
                VStack(alignment: .leading, spacing: 4) {
                    Text("쿠키 🐶").font(.caption).fontWeight(.semibold).foregroundColor(.orange)
                    ZStack(alignment: .bottomLeading) {
                        Text(cookieVM.currentMessage)
                            .font(.body).foregroundColor(.primary)
                            .padding(.horizontal, 16).padding(.vertical, 12)
                            .background(RoundedRectangle(cornerRadius: 18).fill(Color(.systemBackground)).shadow(color: .black.opacity(0.08), radius: 4))
                        BubbleTailShape().fill(Color(.systemBackground)).frame(width: 16, height: 12).offset(x: -8, y: 0)
                    }
                }
                .accessibilityLabel("쿠키: \(cookieVM.currentMessage)")
            }
            Spacer()
        }
        .padding(.horizontal, 16).padding(.vertical, 8)
        .animation(.easeInOut(duration: 0.3), value: cookieVM.currentMessage)
    }
}

struct CookieCharacterView: View {
    let emotion: CookieEmotion
    @State private var isAnimating = false

    var body: some View {
        ZStack {
            Circle().fill(Color.orange.opacity(0.1)).frame(width: 120, height: 120)
            Text(emotion.emoji).font(.system(size: 72))
        }
        .scaleEffect(isAnimating ? 1.05 : 0.95)
        .animation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true), value: isAnimating)
        .onAppear { isAnimating = true }
        .accessibilityHidden(true)
    }
}
