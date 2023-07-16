//
//  MVNode.swift
//  
//
//  Created by dalong on 2023/6/1.
//

import Foundation

@objc
public class MVNode: NSObject {
  var caption: String?
  weak var parent: MVNode?
  var children: [MVNode]
  var dataRange: Range<Int>
  var details: MVTable
  var userInfo: MVNodeUserInfo
  var detailsOffset: UInt64
    
  override init() {
    caption = ""
    parent = nil
    children = [MVNode]()
    dataRange = 3..<5
    userInfo = MVNodeUserInfo()
    detailsOffset = 0
  }
  
  func child(at index: Int) -> MVNode {
    children[index]
  }

  func numberOfChildren() -> Int {
    children.count
  }

  func insert(node: MVNode) {
    guard let layout = userInfo.layout else { return }
    layout.dataController?.treeLock.lock()
    
    let insertIndex = children.firstIndex { node.dataRange.lowerBound < $0.dataRange.lowerBound }
//    
//    NotificationCenter.default.post(name: NSNotification.Name.dataTreeWillChange,
//                                    object: layout.dataController)
    if let insertIndex {
      children.insert(node, at: insertIndex)
    } else {
      children.append(node)
    }
//    NotificationCenter.default.post(name: NSNotification.Name.dataTreeDidChanged,
//                                    object: layout.dataController)

    layout.dataController?.updateTreeView(self)
    layout.dataController?.treeLock.unlock()
  }
  
  func insert(_ caption: String, location: Int, length: Int) -> MVNode {
    let node = MVNode()
    node.caption = caption
    node.dataRange = location..<(location + length)
    node.parent = self
    node.userInfo.merge(userInfo)
    insert(node: node)
    return node
  }
  
  func insertChildWithDetails(_ caption: String, location: Int, length: Int, server: inout MVNodeSaver) -> MVNode? {
    guard let layout = userInfo.layout else { return nil }

    let node = insert(caption, location: location, length: length)
    node.details = MVTable(archiver: layout.archiver)
    server.node = node
    return node
  }
  
  func findNode(by aUserInfo: MVNodeUserInfo) -> MVNode? {
    if self.userInfo == aUserInfo {
      return self
    }
    for n in children where n.findNode(by: aUserInfo) {
      return n
    }
    return nil
  }
  
  func openDetails() {
    guard let layout = userInfo.layout else { return nil }

    
    MVLayout * layout = [userInfo objectForKey:MVLayoutUserInfoKey];
    FILE * pFile = fopen(CSTRING(layout.archiver.swapPath), "r");
    if (pFile != NULL)
    {
      if (details != nil) // saving in progress
      {
        details.swapFile = pFile;
      }
      else if (detailsOffset != 0) // saved and has content
      {
        [self loadFromFile:pFile];
      }
    }
  }

  //-----------------------------------------------------------------------------
  - (void)closeDetails
  {
    if (details.swapFile != NULL)
    {
      fclose(details.swapFile);
      details.swapFile = NULL;
    }
  }

  //-----------------------------------------------------------------------------
  - (void)sortDetails
  {
    MVLayout * layout = [userInfo objectForKey:MVLayoutUserInfoKey];
    [layout.dataController updateStatus:MVStatusTaskStarted];
    [details sortByOffset];
    [layout.dataController updateStatus:MVStatusTaskTerminated];
  }

  //----------------------------------------------------------------------------
  - (void)filterDetails: (NSString *)filter
  {
    MVLayout * layout = [userInfo objectForKey:MVLayoutUserInfoKey];
    [layout.dataController updateStatus:MVStatusTaskStarted];
    [layout.archiver suspend];
    [details applyFilter:filter];
    [layout.archiver resume];
    [layout.dataController updateStatus:MVStatusTaskTerminated];
  }

  //-----------------------------------------------------------------------------
  - (void)saveToFile:(FILE *)pFile
  {
      MVLayout * layout = [userInfo objectForKey:MVLayoutUserInfoKey];
      [layout.dataController updateStatus:MVStatusTaskStarted];
    
      off_t filePos = ftello(pFile);
      // XXX: error check
      if (filePos == -1) {
          NSLog(@"MVNode saveToFile: ftello failed: %s", strerror(errno));
      }
      details.swapFile = pFile;
      [details saveIndexes];
      detailsOffset = filePos;
      // clear the * prefix
      [layout.dataController updateTreeView:self];
      // update the details table
      if (self == layout.dataController.selectedNode) {
          [self openDetails];
          [details applyFilter:nil];
      }
    
      [layout.dataController updateStatus:MVStatusTaskTerminated];
  }

  //-----------------------------------------------------------------------------
  - (void)loadFromFile:(FILE *)pFile
  {
    MVLayout * layout = [userInfo objectForKey:MVLayoutUserInfoKey];
    [layout.dataController updateStatus:MVStatusTaskStarted];
    details = [MVTable tableWithArchiver:layout.archiver];
    details.swapFile = pFile;
    NSParameterAssert(detailsOffset != 0);
    fseek (pFile, detailsOffset, SEEK_SET);
    [details loadIndexes];
    [layout.dataController updateStatus:MVStatusTaskTerminated];
  }

  //-----------------------------------------------------------------------------
  -(void)clear
  {
    MVLayout * layout = [userInfo objectForKey:MVLayoutUserInfoKey];
    if (layout.dataController.selectedNode != self)
    {
      details = nil;
    }
  }
  
}

extension MVNode: MVSerializing {
  func loadFromFile(_ fileHandle: FileHandle) {
    
  }
  
  func saveToFile(_ fileHandle: FileHandle) {
    
  }
  
  func clear() {
    
  }
}

extension MVNode {
  public override var description: String {
    "\(super.description) [\(String(describing: caption))]"
  }
}
