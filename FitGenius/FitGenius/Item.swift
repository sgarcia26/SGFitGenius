//
//  Item.swift
//  FitGenius
//
//  Created by Cesia  Flores on 1/27/25.
//

import SwiftData
import Foundation

// Represents a basic SwiftData model item with a name and creation date
@Model
class Item {
    var name: String
    var dateCreated: Date

    init(name: String, dateCreated: Date = Date()) {
        self.name = name
        self.dateCreated = dateCreated
    }
}
