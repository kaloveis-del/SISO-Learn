import SwiftUI

struct YouTubeLearningView: View {
    @State var viewModel: LearningSessionViewModel
    let videoId: String
    @State private var isVideoReady = false

    var body: some View {
        GeometryReader { geo in
            HStack(spacing: 0) {
                // 좌측 50%: YouTube 영상
                VStack {
                    YouTubePlayerView(videoId: videoId, isReady: $isVideoReady)
                        .aspectRatio(16/9, contentMode: .fit)
                        .frame(maxWidth: .infinity)
                    Spacer()
                }
                .frame(width: geo.size.width * 0.5)
                .background(Color.black)

                Divider()

                // 우측 50%: 쿠키 학습 패널
                CookieLearningView(viewModel: viewModel)
                    .frame(width: geo.size.width * 0.5)
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { viewModel.startSession() }
    }
}
