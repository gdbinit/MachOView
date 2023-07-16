//
//  MVLayout.swift
//  
//
//  Created by d on 2023/07/16.
//

import Foundation

final class MVLayout: NSObject {
  weak var rootNode: MVNode?
  weak var dataController: MVDataController?
  let imageOffset: Int
  let imageSize: Int
  let backgroundThread: Thread
  let archiver: MVArchiver
  
  init(rootNode: MVNode? = nil, dataController: MVDataController? = nil, imageOffset: Int, imageSize: Int, backgroundThread: Thread, archiver: MVArchiver) {
    self.rootNode = rootNode
    self.dataController = dataController
    self.imageOffset = rootNode?.dataRange.location
    self.imageSize = rootNode?.dataRange.length
    self.backgroundThread = Thread(target: self, selector: #selector(doBackgroundTasks), object: nil)
    
    do {
      let swapFilePath = try? createTemporaryFile()
      let swapFileUrl = URL(fileURLWithPath: swapFilePath)
      let swapPath = swapFileUrl.append(path: ".\(dataController.fileName)")
      self.archiver = MVArchiver(path: swapPath)
    } catch {
      return nil
    }
  }
  
  func createTemporaryFile() throws -> URL {
      var templateCString = URL.tempDirectory.utf8CString
      let fd = mkstemp(&templateCString)
      if fd != -1 {
          close(fd)
          return URL(fileURLWithPath: String(cString: templateCString))
      } else {
          throw NSError(domain: NSPOSIXErrorDomain, code: Int(errno), userInfo: nil)
      }
  }
  
  func image(at location: Int) -> Data.SubSequence {
    dataController?.realData[location...]
  }
  
  func print(exception: NSException, caption: String) {
    printf("\(Exception): Exception (\(caption)), \(exception.name)")
    printf("     Reason: \(exception.reason)");
    printf("  User Info: \(exception.userInfo)");
    printf("  Backtrace: \(exception.callStackSymbols)");
    }
  }

  var is64bit: Bool {
    false
  }
  
  func doMainTasks() {
    
  }
  
  func doBackgroundTasks() {
    archiver.halt()
  }
  
  func convertToRVA(offsetStr: String) -> String {
    ""
  }
  
  func findNode(by userInfo: [String: Any]) -> MVNode? {
    dataController?.treeLock.lock()
    let node = rootNode?.find(byUserInfo: userInfo)
    dataController.treeLock.unlock()
    return node;
  }
  
  func createDataNode(parent: MVNode, caption: String, location: Int, length: Int) -> MVNode {
    let node = parent.insertChild(caption, location: location, length: length)
    return node;
  }
  
  var description: String {
    "[\(rootNode.caption)]"
  }
}
