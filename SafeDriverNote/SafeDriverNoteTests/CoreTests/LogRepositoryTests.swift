import XCTest
@testable import SafeDriverNote

final class LogRepositoryTests: XCTestCase {
    override func setUp() {
        super.setUp()
        GlobalModelContext.container = TestSupport.makeInMemoryContainer()
    }

    func testAddAndFetchAll() throws {
        let repo = LogRepositorySwiftData()
        let entry = LogEntry(type: .mistake, detail: "Test detail")
        try repo.add(entry)
        let all = try repo.fetchAll()
        XCTAssertEqual(all.count, 1)
        XCTAssertEqual(all.first?.detail, "Test detail")
    }

    func testFilterByType() throws {
        let repo = LogRepositorySwiftData()
        try repo.add(LogEntry(type: .mistake, detail: "A"))
        try repo.add(LogEntry(type: .success, detail: "B"))
        let mistakes = try repo.fetch(by: .mistake)
        XCTAssertEqual(mistakes.count, 1)
        XCTAssertEqual(mistakes.first?.detail, "A")
    }

    func testUpdateEntry() throws {
        let repo = LogRepositorySwiftData()
        let e = LogEntry(type: .mistake, detail: "Old", tags: ["a"])
        try repo.add(e)
        try repo.update(e) { entry in
            entry.detail = "New"
            entry.type = .success
            entry.tags = ["b","c"]
        }
        let all = try repo.fetchAll()
        XCTAssertEqual(all.first?.detail, "New")
        XCTAssertEqual(all.first?.type, .success)
        XCTAssertEqual(all.first?.tags, ["b","c"])
    }
}
