import XCTest
@testable import SafeDriverNote

final class ChecklistScoreTests: XCTestCase {
    func testScoreCalculation() throws {
        let repo = ChecklistRepositorySwiftData() // NOTE: Needs SwiftData context in real test
        let vm = ChecklistViewModel(repository: repo)
        // Initially 0%
        XCTAssertEqual(vm.score, 0)
    }
}
