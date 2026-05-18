import XCTest
@testable import SISOLearn

final class KeychainServiceTests: XCTestCase {

    var sut: KeychainService!

    override func setUp() {
        super.setUp()
        sut = KeychainService()
        try? sut.delete()
    }

    override func tearDown() {
        try? sut.delete()
        super.tearDown()
    }

    func test_saveAndLoad_roundTrip() throws {
        let testKey = "AIzaTestKey1234567890123456789012345"
        try sut.save(apiKey: testKey)
        let loaded = try sut.load()
        XCTAssertEqual(loaded, testKey)
    }

    func test_hasAPIKey_returnsTrueAfterSave() throws {
        XCTAssertFalse(sut.hasAPIKey())
        try sut.save(apiKey: "AIzaTestKey1234567890123456789012345")
        XCTAssertTrue(sut.hasAPIKey())
    }

    func test_delete_removesKey() throws {
        try sut.save(apiKey: "AIzaTestKey1234567890123456789012345")
        try sut.delete()
        XCTAssertFalse(sut.hasAPIKey())
    }

    func test_load_throwsWhenNoKey() {
        XCTAssertThrowsError(try sut.load())
    }

    func test_isValidFormat_correctKey() {
        let useCase = ManageAPIKeyUseCase()
        XCTAssertTrue(useCase.isValidFormat("AIzaTestKey1234567890123456789012345"))
        XCTAssertFalse(useCase.isValidFormat("AIzaShort"))
        XCTAssertFalse(useCase.isValidFormat("sk-TestKey1234567890123456789012345"))
    }
}
