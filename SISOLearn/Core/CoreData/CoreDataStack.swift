import CoreData
import Foundation

final class CoreDataStack {

    static let shared = CoreDataStack()

    private init() {}

    lazy var persistentContainer: NSPersistentContainer = {
        let container = NSPersistentContainer(name: "SISOLearnModel")

        // Lightweight Migration 자동 설정
        let description = container.persistentStoreDescriptions.first
        description?.shouldMigrateStoreAutomatically = true
        description?.shouldInferMappingModelAutomatically = true

        container.loadPersistentStores { _, error in
            if let error = error {
                fatalError("CoreData 로드 실패: \(error.localizedDescription)")
            }
        }
        container.viewContext.automaticallyMergesChangesFromParent = true
        container.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        return container
    }()

    var viewContext: NSManagedObjectContext {
        persistentContainer.viewContext
    }

    /// 백그라운드 저장용 컨텍스트 (메인 스레드 블로킹 방지)
    func newBackgroundContext() -> NSManagedObjectContext {
        let context = persistentContainer.newBackgroundContext()
        context.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        return context
    }

    /// 변경사항 저장
    func save(context: NSManagedObjectContext? = nil) throws {
        let ctx = context ?? viewContext
        guard ctx.hasChanges else { return }
        try ctx.save()
    }
}

// MARK: - 테스트용 인메모리 스택
extension CoreDataStack {
    static func inMemory() -> CoreDataStack {
        let stack = CoreDataStack()
        let description = NSPersistentStoreDescription()
        description.type = NSInMemoryStoreType
        stack.persistentContainer.persistentStoreDescriptions = [description]
        stack.persistentContainer.loadPersistentStores { _, error in
            if let error = error { fatalError("InMemory CoreData 실패: \(error)") }
        }
        return stack
    }
}
