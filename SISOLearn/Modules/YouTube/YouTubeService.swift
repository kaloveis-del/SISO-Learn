import Foundation

struct YouTubeService {

    /// YouTube URL에서 videoId 추출
    func extractVideoId(from urlString: String) -> String? {
        guard let url = URL(string: urlString) else { return nil }

        // youtu.be 단축 URL
        if url.host == "youtu.be" {
            return url.pathComponents.dropFirst().first
        }

        // youtube.com/watch?v=
        if let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
           let item = components.queryItems?.first(where: { $0.name == "v" }) {
            return item.value
        }

        // youtube.com/embed/VIDEO_ID
        if let idx = url.pathComponents.firstIndex(of: "embed") {
            let next = url.pathComponents.index(after: idx)
            if next < url.pathComponents.endIndex {
                return url.pathComponents[next]
            }
        }
        return nil
    }

    /// 썸네일 URL 생성
    func thumbnailURL(for videoId: String) -> URL? {
        URL(string: "https://img.youtube.com/vi/\(videoId)/hqdefault.jpg")
    }
}
