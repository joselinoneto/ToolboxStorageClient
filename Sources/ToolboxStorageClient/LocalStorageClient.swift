//
//  StorageClient.swift
//  
//
//  Created by José Neto on 27/11/2022.
//

import Foundation
import GRDB

public class LocalStorageClient<T> where T: LocalItem {
    public let dbQueue: DatabaseQueue?
    
    public init(pathToSqlite: String? = nil) {
        if let dbFile = pathToSqlite {
            dbQueue = try? DatabaseQueue(path: dbFile)
        } else {
            // in memory
            dbQueue = try? DatabaseQueue()
            createMockTable()
        }
    }
    
    public func save(item: T) throws {
        try dbQueue?.write({ db in
            if try T.fetchOne(db, key: item.id) == nil {
                try item.insert(db)
            }
        })
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
    
    private func createMockTable() {
        try? dbQueue?.write { db in
            try db.create(table: "NoteStorage", options: .ifNotExists) { t in
                t.column("id", .text).primaryKey()
                t.column("title", .text)
            }
        }
    }
}
