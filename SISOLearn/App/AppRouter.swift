import SwiftUI

/// 앱 전체 화면 라우팅을 담당
/// NavigationPath 기반으로 화면 전환을 관리한다
@MainActor
final class AppRouter: ObservableObject {

    @Published var path = NavigationPath()
    @Published var selectedProfile: String? = nil  // Task 4에서 Profile 타입으로 교체
    @Published var hasAPIKey: Bool = false          // Task 3에서 Keychain 연동

    enum Route: Hashable {
        case profileSelection
        case profileCreation
        case home
        case settings
        case progress
        case learningSession
        case youtubeLearning
    }

    func navigate(to route: Route) {
        path.append(route)
    }

    func goBack() {
        path.removeLast()
    }

    func goToRoot() {
        path.removeLast(path.count)
    }
}
