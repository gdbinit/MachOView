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


//- (void const *)        imageAt:(uint64_t)location NS_RETURNS_INNER_POINTER;
//- (void)                printException:(NSException *)exception caption:(NSString *)caption;
//- (BOOL)                is64bit;
//- (void)                doMainTasks;
//- (void)                doBackgroundTasks;
//- (NSString *)          convertToRVA: (NSString *)offsetStr;
//- (MVNode *)            findNodeByUserInfo:(NSDictionary *)userInfo;
//
//- (MVNode *)            createDataNode:(MVNode *)parent
//                               caption:(NSString *)caption
//                              location:(uint64_t)location
//                                length:(uint64_t)length;
//
//@end
