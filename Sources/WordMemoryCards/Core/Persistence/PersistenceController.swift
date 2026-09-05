import CoreData
import Foundation

@MainActor
final class PersistenceController: ObservableObject {
    @Published private(set) var loadErrorMessage: String?
    @Published private(set) var isReady = false

    let container: NSPersistentContainer

    init(inMemory: Bool = false) {
        container = NSPersistentContainer(name: "WordMemoryCards")

        if inMemory {
            let description = NSPersistentStoreDescription()
            description.type = NSInMemoryStoreType
            description.shouldAddStoreAsynchronously = false
            container.persistentStoreDescriptions = [description]
        }

        for description in container.persistentStoreDescriptions {
            description.shouldMigrateStoreAutomatically = true
            description.shouldInferMappingModelAutomatically = true
        }

        container.loadPersistentStores { [weak self] _, error in
            guard let self else { return }
            if let error {
                Task { @MainActor in
                    self.loadErrorMessage = error.localizedDescription
                }
                return
            }

            let context = self.container.newBackgroundContext()
            context.mergePolicy = NSErrorMergePolicy
            context.undoManager = nil
            do {
                try context.performAndWait {
                    _ = try FSRSMigrationService.migrateAll(in: context)
                }
                Task { @MainActor in self.isReady = true }
            } catch {
                Task { @MainActor in
                    self.loadErrorMessage = "升级学习记录失败：\(error.localizedDescription)"
                }
            }
        }

        container.viewContext.automaticallyMergesChangesFromParent = true
        container.viewContext.mergePolicy = NSErrorMergePolicy
        container.viewContext.undoManager = nil
    }

    func dismissLoadError() {
        loadErrorMessage = nil
    }

    func newBackgroundContext() -> NSManagedObjectContext {
        let context = container.newBackgroundContext()
        context.mergePolicy = NSErrorMergePolicy
        context.undoManager = nil
        return context
    }
}
