//
//  MVRow.swift
//  
//
//  Created by dalong on 2023/6/1.
//

import Foundation
import AppKit
import FileHandleExt

public final class MVRow: NSObject {
    let column: MVColumn
    let attributes: [String: String]
    let offset: UInt64
    var columnsOffset: UInt64
    let attributesOffset: UInt64
    let deleted: Bool
    let dirty: Bool
    
    init(column: MVColumn,
         attributes: [String : String],
         offset: UInt64,
         columnsOffset: UInt64,
         attributesOffset: UInt64,
         deleted: Bool,
         dirty: Bool) {
        self.column = column
        self.attributes = attributes
        self.offset = offset
        self.columnsOffset = columnsOffset
        self.attributesOffset = attributesOffset
        self.deleted = deleted
        self.dirty = dirty
    }
    
    func column(at index: ColumnProperty) -> String {
        switch index {
        case .offset:
            return column.offsetStr
        case .data:
            return column.dataStr
        case .description:
            return column.descriptionStr
        case .value:
            return column.valueStr
        }
    }
    
    func replaceColumn(at index: ColumnProperty, with string: String) {
        columnsOffset = 0
        switch index {
        case .offset:
            column.offsetStr = string
        case .data:
            column.dataStr = string
        case .description:
            column.descriptionStr = string
        case .value:
            column.valueStr = string
        }
    }
    
}

extension MVRow: MVSerializing {
    func loadFromFile(_ fileHandle: FileHandle) {
        
    }
    
    func saveToFile(_ fileHandle: FileHandle) {
        
    }
    
    func clear() {
        
    }
}
extension MVRow {
    
    func write(_ string: String?, to fileHandle: FileHandle) {
        if let data = string?.data(using: .utf8) {
            fileHandle.write(data)
        } else {
            let char: Character = "\0"
            let data = String(char).data(using: .utf8)!
            fileHandle.write(data)
        }
    }
    
    func readString(from fileHandle: FileHandle) -> String? {
        var data = Data()
        var char: UInt8 = 0
        repeat {
            char = fileHandle.readData(ofLength: 1).first ?? 0
            data.append(char)
        } while char != 0
        return String(data: data, encoding: .utf8)
    }
    
    func writeColor(_ color: NSColor, to fileHandle: FileHandle) {
      let colorOrdinal = MVColorOrdinal(color: color)?.rawValue ?? 0
      fileHandle.writeByte(colorOrdinal)
      if colorOrdinal == 0 {
        fileHandle.writeColor(color)
      }
    }

}
