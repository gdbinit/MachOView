//
//  MVNodeSaver.swift
//
//
//  Created by d on 2023/07/16.
//

import Foundation

class MVNodeSaver {
  weak var node: MVNode?
    
  deinit {
    node?.nodeUserInfo.layout?.archiver.addObject(toSave: node)
  }
}
