//
//  MVColumns.swift
//
//
//  Created by dalong on 2023/6/1.
//

import Foundation

fileprivate var nrow_loaded: Int = 0

public enum ColumnProperty: Int {
  case offset = 0
  case data = 1
  case description = 2
  case value = 3
}

@objcMembers
public final class MVColumns: NSObject {
  public var offsetStr: String
  public var dataStr: String
  public var descriptionStr: String
  public var valueStr: String

  public init(offsetStr: String, dataStr: String, descriptionStr: String, valueStr: String) {
    self.offsetStr = offsetStr
    self.dataStr = dataStr
    self.descriptionStr = descriptionStr
    self.valueStr = valueStr
    
    nrow_loaded += 1
  }
  
  deinit {
    nrow_loaded -= 1
  }
}
