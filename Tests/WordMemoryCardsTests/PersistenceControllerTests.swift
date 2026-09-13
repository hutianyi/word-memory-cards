import CoreData
import XCTest
@testable import WordMemoryCards

final class PersistenceControllerTests: XCTestCase {
    @MainActor
    func testPreviousStoreMigratesWithoutLosingWords() throws {
        let bundle = Bundle(for: WordEntity.self)
        let modelDirectory = try XCTUnwrap(bundle.url(forResource: "WordMemoryCards", withExtension: "momd"))
        let oldModel = try XCTUnwrap(NSManagedObjectModel(contentsOf: modelDirectory.appendingPathComponent("WordMemoryCards.mom")))
        let newModel = PersistenceController(inMemory: true).container.managedObjectModel
        let url = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString + ".sqlite")
        let originalID = UUID()
        let oldCoordinator = NSPersistentStoreCoordinator(managedObjectModel: oldModel)
        let oldStore = try oldCoordinator.addPersistentStore(ofType: NSSQLiteStoreType, configurationName: nil, at: url)
        let oldContext = NSManagedObjectContext(concurrencyType: .mainQueueConcurrencyType)
        oldContext.persistentStoreCoordinator = oldCoordinator
        let word = NSEntityDescription.insertNewObject(forEntityName: "WordEntity", into: oldContext)
        word.setValuesForKeys(["id": originalID, "english": "zebra", "normalizedEnglish": "zebra",
                              "chinese": "斑马", "createdAt": Date(), "updatedAt": Date()])
        try oldContext.save()
        oldContext.reset()
        try oldCoordinator.remove(oldStore)
        let newCoordinator = NSPersistentStoreCoordinator(managedObjectModel: newModel)
        _ = try newCoordinator.addPersistentStore(ofType: NSSQLiteStoreType, configurationName: nil, at: url,
            options: [NSMigratePersistentStoresAutomaticallyOption: true, NSInferMappingModelAutomaticallyOption: true])
        let context = NSManagedObjectContext(concurrencyType: .mainQueueConcurrencyType)
        context.persistentStoreCoordinator = newCoordinator
        let restored = try XCTUnwrap(context.fetch(WordEntity.fetchRequest()).first)
        XCTAssertEqual(restored.id, originalID)
        XCTAssertEqual(restored.english, "zebra")
        XCTAssertEqual(restored.importPosition, 0)
        try newCoordinator.destroyPersistentStore(at: url, ofType: NSSQLiteStoreType)
    }

    @MainActor
    func testModelContainsTheFourRequiredEntities() {
        let persistence = PersistenceController(inMemory: true)
        let names = Set(persistence.container.managedObjectModel.entities.compactMap(\.name))

        XCTAssertEqual(
            names,
            ["WordEntity", "ReviewStateEntity", "ReviewEventEntity", "StudySessionEntity"]
        )
    }

    @MainActor
    func testAWordCanOwnTwoIndependentReviewStates() throws {
        let persistence = PersistenceController(inMemory: true)
        let context = persistence.container.viewContext
        let now = Date()

        let word = WordEntity(context: context)
        word.id = UUID()
        word.english = "apple"
        word.normalizedEnglish = "apple"
        word.chinese = "苹果"
        word.createdAt = now
        word.updatedAt = now

        for direction in ReviewDirection.allCases {
            let state = ReviewStateEntity(context: context)
            state.id = UUID()
            state.direction = direction.rawValue
            state.level = 0
            state.nextReviewDate = now
            state.createdAt = now
            state.updatedAt = now
            state.word = word
        }

        try context.save()

        let request = ReviewStateEntity.fetchRequest()
        request.predicate = NSPredicate(format: "word == %@", word)
        let states = try context.fetch(request)

        XCTAssertEqual(states.count, 2)
        XCTAssertEqual(Set(states.map(\.direction)), Set(ReviewDirection.allCases.map(\.rawValue)))
        XCTAssertTrue(states.allSatisfy { $0.level == 0 })
    }
}
