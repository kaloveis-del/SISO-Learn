import SwiftUI

struct SkeletonView: View {
    @State private var isAnimating = false

    var body: some View {
        RoundedRectangle(cornerRadius: 8)
            .fill(
                LinearGradient(
                    colors: [Color(.systemGray5), Color(.systemGray4), Color(.systemGray5)],
                    startPoint: .leading, endPoint: .trailing
                )
            )
            .opacity(isAnimating ? 0.6 : 1.0)
            .animation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true), value: isAnimating)
            .onAppear { isAnimating = true }
    }
}

struct ExplanationSkeletonView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            SkeletonView().frame(height: 20)
            SkeletonView().frame(height: 20).padding(.trailing, 40)
            SkeletonView().frame(height: 20).padding(.trailing, 80)
            SkeletonView().frame(height: 20).padding(.trailing, 20)
        }
        .padding()
        .background(Color(.systemBackground)).cornerRadius(16)
        .shadow(color: .black.opacity(0.06), radius: 4)
    }
}
