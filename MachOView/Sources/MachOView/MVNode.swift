//
//  MVNode.swift
//  
//
//  Created by dalong on 2023/6/1.
//

import Foundation

@objc
public class MVNode: NSObject, MVSerializing {
    let caption: String
    weak var parent: MVNode?
    var children: [MVNode]
    var dataRange: Range
    
    init(caption: String, parent: MVNode? = nil, children: [MVNode]) {
        self.caption = caption
        self.parent = parent
        self.children = children
    }
}

@interface MVNode : NSObject <MVSerializing>
{
  NSString *            caption;
  MVNode *              __weak parent;
  NSMutableArray *      children;
  NSRange               dataRange;
  MVTable *             details;
  NSMutableDictionary * userInfo;
  off_t                 detailsOffset;
}

@property (nonatomic)                   NSString *            caption;
@property (nonatomic,weak)      MVNode *              parent;
@property (nonatomic)                   NSRange               dataRange;
@property (nonatomic)                   MVTable *             details;
@property (nonatomic)                   NSMutableDictionary * userInfo;
@property (nonatomic)                   off_t              detailsOffset;

- (NSUInteger)          numberOfChildren;
- (MVNode *)            childAtIndex:(NSUInteger)n;
- (MVNode *)            insertChild:(NSString *)_caption location:(uint64_t)location length:(uint64_t)length;
- (MVNode *)            insertChildWithDetails:(NSString *)_caption location:(uint64_t)location length:(uint64_t)length saver:(MVNodeSaver &)saver;
- (MVNode *)            findNodeByUserInfo:(NSDictionary *)uinfo;
- (void)                openDetails;  // open swap file for reading details on demand
- (void)                closeDetails; // close swap file
- (void)                sortDetails;
- (void)                filterDetails:(NSString *)filter;
- (void)                loadFromFile:(FILE *)pFile;
- (void)                saveToFile:(FILE *)pFile;

@end
