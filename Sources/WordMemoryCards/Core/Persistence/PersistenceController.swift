import CoreData
import Foundation

@MainActor
final class PersistenceController: ObservableObject {
    @Published private(set) var loadErrorMessage: String?

    let container: NSPersistentContainer

    init(inMemory: Bool = false) {
        container = NSPersistentContainer(name: "WordMemoryCards")

        if inMemory {
            let description = NSPersistentStoreDescription()
            description.type = NSInMemoryStoreType
            description.shouldAddStoreAsynchronously = false
            container.persistentStoreDescriptions = [description]
        }

        container.loadPersistentStores { [weak self] _, error in
            guard let error else { return }
            Task { @MainActor in
                self?.loadErrorMessage = error.localizedDescription
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
