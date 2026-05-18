import SwiftUI
import Observation

@Observable
@MainActor
final class AppRouter {
    var path = NavigationPath()
    var selectedProfile: String? = nil
    var hasAPIKey: Bool = false

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
