//
//  File.swift
//  
//
//  Created by José Neto on 27/11/2022.
//

import Foundation
import GRDB
public protocol LocalItem: Codable, Hashable, FetchableRecord, PersistableRecord {
    var id: Int? { get set }
}
