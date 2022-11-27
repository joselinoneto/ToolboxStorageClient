//
//  File.swift
//  
//
//  Created by José Neto on 27/11/2022.
//

import Foundation
import GRDB
public protocol LocalItem: Codable, FetchableRecord, PersistableRecord {
    var id: UUID? { get set }
}
