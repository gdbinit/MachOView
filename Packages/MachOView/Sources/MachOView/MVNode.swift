//
//  MVNode.swift
//  
//
//  Created by dalong on 2023/6/1.
//

import Foundation

@objc
public class MVNode: NSObject, MVSerializing {
  func loadFromFile(_ fileHandle: FileHandle) {
    
  }
  
  func saveToFile(_ fileHandle: FileHandle) {
    
  }
  
  func clear() {
    
  }
  
    let caption: String
    weak var parent: MVNode?
    var children: [MVNode]
    var dataRange: Range<Int>
    
    init(caption: String, parent: MVNode? = nil, children: [MVNode]) {
        self.caption = caption
        self.parent = parent
        self.children = children
    }
}
