//
//  MVNodeUserInfo.swift
//  
//
//  Created by d on 2023/07/16.
//

import Foundation

class MVNodeUserInfo {
  var layout: MVLayout?
  
  func merge(_ other: MVNodeUserInfo) {
    layout = other.layout
  }
}

extension MVNodeUserInfo: Equatable {}
