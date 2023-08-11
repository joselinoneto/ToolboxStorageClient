//
//  StorageClient.swift
//  
//
//  Created by José Neto on 27/11/2022.
//

import Foundation
import GRDB
import OSLog

public extension Logger {
    static let dataLog = Logger(subsystem: "group.app.zeneto.daily.apod", category: "ApodData")
}

public class LocalStorageClient<T> where T: LocalItem {
    @Published public var items: [T]?

    private var _dbQueue: DatabaseQueue?
    public var dbQueue: DatabaseQueue? {
        get {
            if _dbQueue != nil {
                return _dbQueue
            } else {
                var config = Configuration()
                config.prepareDatabase { db in
//                    db.trace() { item in
//                        Logger.dataLog.trace("SQL: \(item.expandedDescription)")
//                    }
                }
                if let pathFile = pathFile {
                    _dbQueue = try? DatabaseQueue(path: pathFile, configuration: config)
                    return _dbQueue
                } else {
                    _dbQueue = try? DatabaseQueue()
                    return _dbQueue
                }
            }
        }
        set {
            _dbQueue = newValue
        }
    }
    private var cancellable: AnyDatabaseCancellable?
    private var pathFile: String?
    public init(pathToSqlite: String? = nil) {
        self.pathFile = pathToSqlite

        // in memory
        if pathToSqlite == nil {
            dbQueue = try? DatabaseQueue()
            createMockTable()
        }
    }

    public func save(query: String, arguments: StatementArguments) async throws {
        dbQueue?.asyncWrite({ db in
            try db.execute(sql: query, arguments: arguments)
        }, completion: { _, _ in })
    }

    public func save(item: T) throws {
        try dbQueue?.write({ db in
            try item.save(db)
        })
    }

    public func saveItems(_ items: [T]) async throws {
        dbQueue?.asyncWrite({ db in
            for item in items {
                if try T.fetchOne(db, key: item.id) == nil {
                    try item.save(db)
                }
            }
        }, completion: { _, _ in })
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

    public func deleteAllData() async throws {
        dbQueue?.asyncWrite({ db in
            try T.deleteAll(db)
        }, completion: { _, _ in })
    }

    public func getFilter(_ filters: SQLSpecificExpressible) throws -> [T]? {
        try dbQueue?.read({ db in
            try T.filter(filters).fetchAll(db)
        })
    }

    public func valueObservation() {
        guard let dbQueue = dbQueue else { return }

        let observation = ValueObservation.tracking(T.fetchAll).shared(in: dbQueue)
        cancellable = observation.start { error in
            Logger.dataLog.error("SQL: \(error)")
        } onChange: { [weak self] (objects: [T]) in
            self?.items = objects
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
