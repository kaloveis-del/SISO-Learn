import Foundation

/// 앱 전체 의존성을 관리하는 컨테이너
/// 각 모듈의 UseCase, Repository, Service 인스턴스를 생성하고 주입한다
@MainActor
final class AppDependencyContainer: ObservableObject {

    // MARK: - Core Services (Task 2, 3에서 채워짐)
    // lazy var coreDataStack = CoreDataStack.shared
    // lazy var keychainService = KeychainService()

    // MARK: - 싱글톤
    static let shared = AppDependencyContainer()
    private init() {}
}
