//
//  File.swift
//  
//
//  Created by d on 2023/07/16.
//

import Foundation

extension URL {
  public static var tempDirectory: String {
    let processInfo = ProcessInfo.processInfo
    let shortVersionString = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString")
    return "\(NSTemporaryDirectory())\(processInfo.processName)_\(shortVersionString).XXXXXXXXXXX"
  }
}
