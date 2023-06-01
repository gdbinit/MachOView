//
//  MVSerializing.swift
//  
//
//  Created by dalong on 2023/6/1.
//

import Foundation

protocol MVSerializing {
    func loadFromFile(_ fileHandle: FileHandle)
    func saveToFile(_ fileHandle: FileHandle)
    func clear()
}
