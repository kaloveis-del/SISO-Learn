import SwiftUI

struct SessionCompleteView: View {
    let accuracyRate: Double
    let correctCount: Int
    let totalCount: Int
    let subject: Subject
    var cookieVM: CookieViewModel
    let onDismiss: () -> Void

    var body: some View {
        VStack(spacing: 24) {
            CookieBubbleView(cookieVM: cookieVM)
            ZStack {
                Circle().stroke(Color.orange.opacity(0.2), lineWidth: 12)
                Circle().trim(from: 0, to: accuracyRate)
                    .stroke(Color.orange, style: StrokeStyle(lineWidth: 12, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                VStack {
                    Text("\(Int(accuracyRate * 100))%")
                        .font(.largeTitle).fontWeight(.bold).foregroundColor(.orange)
                    Text("정답률").font(.caption).foregroundColor(.secondary)
                }
            }
            .frame(width: 150, height: 150)
            Text("\(correctCount) / \(totalCount) 문제 정답")
                .font(.title2).foregroundColor(.secondary)
            Button("홈으로 돌아가기") { onDismiss() }
                .buttonStyle(.borderedProminent).tint(.orange).frame(minHeight: 44)
        }
        .padding()
        .onAppear { cookieVM.updateForPhase(.sessionComplete) }
    }
}
