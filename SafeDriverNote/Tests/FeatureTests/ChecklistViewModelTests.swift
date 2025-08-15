import XCTest
@testable import SafeDriverNote

final class ChecklistViewModelTests: XCTestCase {
    override func setUp() {
        super.setUp()
        GlobalModelContext.container = TestSupport.makeInMemoryContainer()
    }

    func testToggleIncreasesScore() throws {
        let repo = ChecklistRepositorySwiftData()
        let vm = ChecklistViewModel(repository: repo)
        XCTAssertEqual(vm.score, 0)
        if let first = vm.record.pre.first { vm.toggle(item: first.key) }
        XCTAssertGreaterThan(vm.score, 0)
    }
}
