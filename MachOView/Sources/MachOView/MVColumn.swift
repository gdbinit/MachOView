//
//  MVColumn.swift
//  
//
//  Created by dalong on 2023/6/1.
//

import Foundation

enum ColumnProperty: Int {
    case offset = 0
    case data = 1
    case description = 2
    case value = 3
}

@objcMembers
public final class MVColumn: NSObject {
    public var offsetStr: String
    public var dataStr: String
    public var descriptionStr: String
    public var valueStr: String

    public init(offsetStr: String, dataStr: String, descriptionStr: String, valueStr: String) {
        self.offsetStr = offsetStr
        self.dataStr = dataStr
        self.descriptionStr = descriptionStr
        self.valueStr = valueStr
    }
}
