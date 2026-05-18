import SwiftUI

struct OfflineBannerView: View {
    @Environment(NetworkMonitor.self) private var networkMonitor

    var body: some View {
        if !networkMonitor.isConnected {
            HStack(spacing: 8) {
                Image(systemName: "wifi.slash")
                Text("인터넷 연결이 없어요")
                    .font(.subheadline).fontWeight(.medium)
            }
            .foregroundColor(.white)
            .padding(.horizontal, 16).padding(.vertical, 8)
            .background(Color.red.opacity(0.85))
            .cornerRadius(20)
            .padding(.top, 8)
            .transition(.move(edge: .top).combined(with: .opacity))
            .animation(.easeInOut, value: networkMonitor.isConnected)
        }
    }
}
