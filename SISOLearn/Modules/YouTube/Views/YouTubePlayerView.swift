import SwiftUI
import WebKit

struct YouTubePlayerView: UIViewRepresentable {
    let videoId: String
    @Binding var isReady: Bool

    func makeUIView(context: Context) -> WKWebView {
        let config = WKWebViewConfiguration()
        config.allowsInlineMediaPlayback = true
        config.mediaTypesRequiringUserActionForPlayback = []
        let webView = WKWebView(frame: .zero, configuration: config)
        webView.navigationDelegate = context.coordinator
        webView.scrollView.isScrollEnabled = false
        webView.backgroundColor = .black
        return webView
    }

    func updateUIView(_ webView: WKWebView, context: Context) {
        let html = """
        <!DOCTYPE html><html><head>
        <meta name="viewport" content="width=device-width, initial-scale=1.0">
        <style>body{margin:0;background:#000}
        .vc{position:relative;width:100%;padding-bottom:56.25%;height:0}
        iframe{position:absolute;top:0;left:0;width:100%;height:100%;border:none}
        </style></head><body>
        <div class="vc"><iframe
          src="https://www.youtube.com/embed/\(videoId)?playsinline=1&rel=0&modestbranding=1"
          allow="accelerometer;autoplay;clipboard-write;encrypted-media;gyroscope;picture-in-picture"
          allowfullscreen></iframe></div></body></html>
        """
        webView.loadHTMLString(html, baseURL: URL(string: "https://www.youtube.com"))
    }

    func makeCoordinator() -> Coordinator { Coordinator(isReady: $isReady) }

    class Coordinator: NSObject, WKNavigationDelegate {
        @Binding var isReady: Bool
        init(isReady: Binding<Bool>) { _isReady = isReady }
        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            isReady = true
        }
    }
}
