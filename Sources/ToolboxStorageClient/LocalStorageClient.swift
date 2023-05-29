//
//  StorageClient.swift
//  
//
//  Created by José Neto on 27/11/2022.
//

import Foundation
import GRDB

public class LocalStorageClient<T> where T: LocalItem {
    @Published public var items: [T]?

    public let dbQueue: DatabaseQueue?
    private var cancellable: AnyDatabaseCancellable?

    public init(pathToSqlite: String? = nil) {
        if let dbFile = pathToSqlite {
            dbQueue = try? DatabaseQueue(path: dbFile)
        } else {
            // in memory
            dbQueue = try? DatabaseQueue()
            createMockTable()
        }
    }

    public func save(query: String) throws {
        try dbQueue?.write({ db in
            try db.execute(sql: query)
        })
    }

    public func save(item: T) throws {
        try dbQueue?.write({ db in
            try item.save(db)
        })
    }

    public func asyncSave(item: T) async throws {
        dbQueue?.asyncWrite({ db in
            try item.save(db)
        }, completion: { _, _ in })
    }
    
    public func get(key: DatabaseValueConvertible) throws -> T? {
        try dbQueue?.read({ db in
            try T.fetchOne(db, key: key)
        })
    }
    
    public func getAll() throws -> [T]? {
        try dbQueue?.read({ db in
            try T.fetchAll(db)
        })
    }

    public func valueObservation() {
        guard let dbQueue = dbQueue else { return }

        let observation = ValueObservation.tracking(T.fetchAll).shared(in: dbQueue)
        cancellable = observation.start { error in
            // Handle error
        } onChange: { (objects: [T]) in
            self.items = objects
        }
    }

    public func cancelObservation() {
        cancellable?.cancel()
    }
    
    private func createMockTable() {
        try? dbQueue?.write { db in
            try db.create(table: "NoteStorage", options: .ifNotExists) { t in
                t.column("id", .text).primaryKey()
                t.column("title", .text)
            }
        }
    }
}
