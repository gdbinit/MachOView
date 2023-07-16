//
//  MVTable.swift
//  
//
//  Created by dalong on 2023/6/1.
//

import Foundation

public final class MVTable: NSObject {
  
  let archiver: MVArchiver
  
  init(archiver: MVArchiver) {
    self.archiver = archiver
  }

}
