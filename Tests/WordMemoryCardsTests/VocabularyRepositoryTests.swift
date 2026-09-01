import XCTest
@testable import WordMemoryCards

final class VocabularyRepositoryTests: XCTestCase {
    @MainActor
    func testImportCreatesOneWordAndTwoReviewStatesWithoutResettingOnRepeat() async throws {
        let persistence = PersistenceController(inMemory: true)
        let repository = VocabularyRepository(container: persistence.container)
        let parseResult = VocabularyParser.parse("apple 苹果")
        let firstAnalysis = try await repository.analyze(parseResult)

        let first = try await repository.importAdditions(firstAnalysis.additions)
        XCTAssertEqual(first.insertedWords, 1)
        XCTAssertEqual(first.createdReviewStates, 2)

        let secondAnalysis = try await repository.analyze(parseResult)
        XCTAssertTrue(secondAnalysis.additions.isEmpty)
        XCTAssertEqual(secondAnalysis.existing.count, 1)

        let context = persistence.container.viewContext
        let words = try context.fetch(WordEntity.fetchRequest())
        let states = try context.fetch(ReviewStateEntity.fetchRequest())
        XCTAssertEqual(words.count, 1)
        XCTAssertEqual(states.count, 2)
    }
}
