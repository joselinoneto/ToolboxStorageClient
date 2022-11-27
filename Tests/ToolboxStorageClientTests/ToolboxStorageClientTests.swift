import XCTest
import ToolboxStorageClient
@testable import ToolboxStorageClient

final class ToolboxStorageClientTests: XCTestCase {
    func testCrud() async throws {
        let id: UUID = UUID()
        let title: String = "Random Title"
        let note = NoteStorage(id: id, title: title)
        note.saveNote()
        let items = NoteStorage.getAll()
        XCTAssertNotNil(items)
        
        let item = NoteStorage.get(key: id)
        XCTAssertNotNil(item)
        XCTAssertEqual(id, item!.id)
    }
}
