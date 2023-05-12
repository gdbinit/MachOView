/*
 *  ArchiveLayout.h
 *  MachOView
 *
 *  Created by psaghelyi on 18/03/2011.
 *
 */

#import "Layout.h"

@interface MVObjectInfo : NSObject
{
  NSString *    name;
  uint64_t      length;
  MVLayout *    __weak layout;
}

@property (nonatomic)                   NSString *  name;
@property (nonatomic)                   uint64_t    length;
@property (nonatomic,weak)  MVLayout *  layout;

@end

@interface ArchiveLayout : MVLayout 
{
  NSMutableDictionary * objectInfoMap; // <(NSNumber)object offset,MVObjectInfo>
}

+ (ArchiveLayout *)     layoutWithDataController:(MVDataController *)dc rootNode:(MVNode *)node;

@end
