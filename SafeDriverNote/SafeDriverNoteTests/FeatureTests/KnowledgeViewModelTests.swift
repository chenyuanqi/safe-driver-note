import XCTest
@testable import SafeDriverNote

final class KnowledgeViewModelTests: XCTestCase {
    override func setUp() {
        super.setUp()
        GlobalModelContext.container = TestSupport.makeInMemoryContainer()
        _ = TestSupport.insertSampleKnowledge(count: 5)
    }

    func testLoadTodayPicksLimit() {
        let repo = KnowledgeRepositorySwiftData()
        let vm = KnowledgeViewModel(repository: repo)
        XCTAssertEqual(vm.today.count, 3)
    }

    func testMarkRemovesCard() {
        let repo = KnowledgeRepositorySwiftData()
        let vm = KnowledgeViewModel(repository: repo)
        guard let first = vm.today.first else { return XCTFail("No cards") }
        vm.mark(card: first)
        XCTAssertFalse(vm.today.contains { $0.id == first.id })
    }
}
