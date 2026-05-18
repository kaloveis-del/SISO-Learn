import XCTest
@testable import SISOLearn

final class YouTubeServiceTests: XCTestCase {
    let sut = YouTubeService()

    func test_extractVideoId_watchURL() {
        let id = sut.extractVideoId(from: "https://www.youtube.com/watch?v=dQw4w9WgXcQ")
        XCTAssertEqual(id, "dQw4w9WgXcQ")
    }

    func test_extractVideoId_shortURL() {
        let id = sut.extractVideoId(from: "https://youtu.be/dQw4w9WgXcQ")
        XCTAssertEqual(id, "dQw4w9WgXcQ")
    }

    func test_extractVideoId_embedURL() {
        let id = sut.extractVideoId(from: "https://www.youtube.com/embed/dQw4w9WgXcQ")
        XCTAssertEqual(id, "dQw4w9WgXcQ")
    }

    func test_extractVideoId_invalidURL_returnsNil() {
        XCTAssertNil(sut.extractVideoId(from: "https://naver.com"))
    }

    func test_extractVideoId_emptyString_returnsNil() {
        XCTAssertNil(sut.extractVideoId(from: ""))
    }

    func test_thumbnailURL_format() {
        let url = sut.thumbnailURL(for: "dQw4w9WgXcQ")
        XCTAssertEqual(url?.absoluteString, "https://img.youtube.com/vi/dQw4w9WgXcQ/hqdefault.jpg")
    }
}
