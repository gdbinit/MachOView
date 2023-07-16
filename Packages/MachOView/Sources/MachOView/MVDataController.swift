//
//  MVDataController.swift
//  
//
//  Created by d on 2023/07/16.
//

import UIKit

class MVDataController: NSObject {
  let fileName: String
  
  let realData: Data
  let treeLock: NSLock
  
  init(fileName: String? = nil, realData: Data) {
    self.fileName = fileName
    self.realData = realData
    self.treeLock = NSLock()
  }
  
  func updateTreeView(node: MVNode) {
    
  }
}
