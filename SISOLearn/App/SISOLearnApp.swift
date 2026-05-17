import SwiftUI

@main
struct SISOLearnApp: App {

    @StateObject private var router = AppRouter()
    @StateObject private var networkMonitor = NetworkMonitor.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(router)
                .environmentObject(networkMonitor)
        }
    }
}

// 임시 ContentView — Task 4에서 ProfileSelectionView로 교체
struct ContentView: View {
    var body: some View {
        VStack(spacing: 20) {
            Text("🐶 SISO-Learn")
                .font(.largeTitle)
                .fontWeight(.bold)
            Text("쿠키와 함께 공부해요!")
                .font(.title2)
                .foregroundColor(.orange)
        }
    }
}
