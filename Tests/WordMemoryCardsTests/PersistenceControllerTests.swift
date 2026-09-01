import CoreData
import XCTest
@testable import WordMemoryCards

final class PersistenceControllerTests: XCTestCase {
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
