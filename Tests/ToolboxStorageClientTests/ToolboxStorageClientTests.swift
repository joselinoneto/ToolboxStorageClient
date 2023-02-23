import Foundation
import XCTest
import ToolboxStorageClient
import GRDB
import Combine

@testable import ToolboxStorageClient

final class ToolboxStorageClientTests: XCTestCase {
    let storage: LocalStorageClient<NoteStorage> = LocalStorageClient<NoteStorage>()

    override func tearDown() {
        storage.cancelObservation()
    }

    override func setUp() {
        storage.valueObservation()
    }

    func testCrud() async throws {
        let id: UUID = UUID()
        let title: String = "Random Title"
        let note = NoteStorage(id: id, title: title)
        try storage.save(item: note)

        let items = try storage.getAll()
        XCTAssertNotNil(items)
        
        let item = try storage.get(key: id)
        XCTAssertNotNil(item)
        XCTAssertEqual(id, item!.id)
    }

    func testObservation() throws {
        var cancellables: Set<AnyCancellable> = []
        
        storage.$items.sink {(notes: [NoteStorage]?) in
            print(notes?.count ?? "")
        }.store(in: &cancellables)

        let id: UUID = UUID()
        let title: String = "Random Title"
        let note = NoteStorage(id: id, title: title)

        let id1: UUID = UUID()
        let title1: String = "Random Title"
        let note1 = NoteStorage(id: id1, title: title1)

        let id2: UUID = UUID()
        let title2: String = "Random Title"
        let note2 = NoteStorage(id: id2, title: title2)

        try storage.save(item: note)
        try storage.save(item: note1)
        try storage.save(item: note2)


        let countEmittedExpected: Int = 5
        let apodPublisher = storage.$items.collect(countEmittedExpected).first()
        let counterArray = try awaitPublisher(apodPublisher)
        XCTAssertEqual(countEmittedExpected, counterArray.count)
    }
}

extension XCTestCase {
    func awaitPublisher<T: Publisher>(
        _ publisher: T,
        timeout: TimeInterval = 10,
        file: StaticString = #file,
        line: UInt = #line
    ) throws -> T.Output {
        // This time, we use Swift's Result type to keep track
        // of the result of our Combine pipeline:
        var result: Result<T.Output, Error>?
        let expectation = self.expectation(description: "Awaiting publisher")

        let cancellable = publisher.sink(
            receiveCompletion: { completion in
                switch completion {
                case .failure(let error):
                    result = .failure(error)
                case .finished:
                    break
                }

                expectation.fulfill()
            },
            receiveValue: { value in
                result = .success(value)
            }
        )

        // Just like before, we await the expectation that we
        // created at the top of our test, and once done, we
        // also cancel our cancellable to avoid getting any
        // unused variable warnings:
        waitForExpectations(timeout: timeout)
        cancellable.cancel()

        // Here we pass the original file and line number that
        // our utility was called at, to tell XCTest to report
        // any encountered errors at that original call site:
        let unwrappedResult = try XCTUnwrap(
            result,
            "Awaited publisher did not produce any output",
            file: file,
            line: line
        )

        return try unwrappedResult.get()
    }
}
