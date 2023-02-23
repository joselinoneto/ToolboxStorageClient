//
//  NoteStorage.swift
//  
//
//  Created by José Neto on 27/11/2022.
//

import Foundation
import ToolboxStorageClient
import GRDB

public struct NoteStorage: LocalItem {
    public var id: UUID?
    public var title: String
    static var storage: LocalStorageClient<NoteStorage> = LocalStorageClient<NoteStorage>()
    
    init(id: UUID? = nil, title: String) {
        self.id = id
        self.title = title
    }
}
