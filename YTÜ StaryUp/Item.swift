//
//  Item.swift
//  YTÜ StaryUp
//
//  Created by Fatih Kadir Akın on 5.02.2026.
//

import Foundation
import SwiftData

@Model
final class Item {
    var timestamp: Date
    
    init(timestamp: Date) {
        self.timestamp = timestamp
    }
}
