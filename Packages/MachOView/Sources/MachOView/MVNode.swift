//
//  MVNode.swift
//  
//
//  Created by dalong on 2023/6/1.
//

import Foundation

@objc
public class MVNode: NSObject {
    let caption: String
    weak var parent: MVNode?
    var children: [MVNode]
    var dataRange: Range<Int>
  var details: MVTable
  var userInfo: [String: Any]
  var detailsOffset: UInt64
    
  override init() {
    caption = ""
    parent = nil
    children = [MVNode]()
    dataRange = 3..<5
    userInfo = [String: Any]()
    detailsOffset = 0
  }
  
  func child(at index: Int) -> MVNode {
    children[index]
  }

  func numberOfChildren() -> Int {
    children.count
  }

  func insert(node: MVNode) {
    let layout = userInfo["MVLayoutUserInfoKey"]
    
    [layout.dataController.treeLock lock];
    
    NSUInteger index = [children indexOfObjectPassingTest:
                        ^(id obj, NSUInteger idx, BOOL *stop)
                        {
                          if (node.dataRange.location < [obj dataRange].location)
                          {
                            *stop = YES;
                            return YES;
                          }
                          return NO;
                        }];
    
    NSNotificationCenter * nc = [NSNotificationCenter defaultCenter];
    [nc postNotificationName:MVDataTreeWillChangeNotification
                      object:layout.dataController];

    if (index == NSNotFound)
    {
      [children addObject:node];
    }
    else
    {
      [children insertObject:node atIndex:index];
    }

    [nc postNotificationName:MVDataTreeDidChangeNotification
                      object:layout.dataController];

    [layout.dataController updateTreeView:self];
    
    [layout.dataController.treeLock unlock];
  }

  //----------------------------------------------------------------------------
  - (MVNode *)insertChild:(NSString *)_caption
              location:(uint64_t)location
                length:(uint64_t)length
  {
    MVNode * node = [[MVNode alloc] init];
    node.caption = _caption;
    node.dataRange = NSMakeRange(location,length);
    node.parent = self;
    [node.userInfo addEntriesFromDictionary:userInfo];
    [self insertNode:node];
    return node;
  }

  //----------------------------------------------------------------------------
  - (MVNode *)insertChildWithDetails:(NSString *)_caption
                         location:(uint64_t)location
                           length:(uint64_t)length
                            saver:(MVNodeSaver &)saver
  {
    MVNode * node = [self insertChild:_caption location:location length:length];
    MVLayout * layout = [userInfo objectForKey:MVLayoutUserInfoKey];
    node.details = [MVTable tableWithArchiver:layout.archiver];
    saver.setNode(node);
    return node;
  }

  //----------------------------------------------------------------------------
  - (MVNode *)findNodeByUserInfo:(NSDictionary *)uinfo
  {
    // act node
    if ([userInfo isEqualToDictionary:uinfo] == YES)
    {
      return self;
    }

    // recursively on childrens
    for (MVNode * node in children)
    {
      MVNode * found = [node findNodeByUserInfo:uinfo];
      if (found != nil)
      {
        return found;
      }
    }
    
    // give up
    return nil;
  }

  //-----------------------------------------------------------------------------
  - (void)openDetails
  {
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
    "\(super.description) [\(caption)]"
  }
}
