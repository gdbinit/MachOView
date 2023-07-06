//
//  MVLayout.swift
//  
//
//  Created by dalong on 2023/6/1.
//

import Foundation

public class MVDataController {}
public class MVArchiver {}

public final class MVLayout: NSObject {
  weak var rootNode: MVNode?
  weak var dataController: MVDataController?
  let imageOffset: UInt64
  let imageSize: UInt64
  let backgroundThread: Thread
  let archiver: MVArchiver
  
  init(rootNode: MVNode? = nil,
       dataController: MVDataController? = nil,
       imageOffset: UInt64,
       imageSize: UInt64,
       backgroundThread: Thread,
       archiver: MVArchiver) {
    self.rootNode = rootNode
    self.dataController = dataController
    self.imageOffset = imageOffset
    self.imageSize = imageSize
    self.backgroundThread = backgroundThread
    self.archiver = archiver
  }
}
