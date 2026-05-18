import SwiftUI
import Observation

@Observable
@MainActor
final class AppDependencyContainer {
    static let shared = AppDependencyContainer()
    private init() {}
}
