/*
 *  Layout.mm
 *  MachOView
 *
 *  Created by psaghelyi on 18/03/2011.
 *
 */

#import "Common.h"
#import "Document.h"
#import "DataController.h"
#import "Layout.h"

//============================================================================
@implementation MVLayout

@synthesize dataController, backgroundThread, archiver;

//-----------------------------------------------------------------------------
- (id)init
{
  NSAssert(NO, @"plain init is not allowed");
  return nil;
}

//-----------------------------------------------------------------------------
- (id)initWithDataController:(MVDataController *)dc rootNode:(MVNode *)node
{
  if (self = [super init]) 
  {
    dataController = dc;
    rootNode = node;
    imageOffset = node.dataRange.location;
    backgroundThread = [[NSThread alloc] initWithTarget:self selector:@selector(doBackgroundTasks) object:nil];
    
    NSString * swapPath = NSSTRING(tempnam(CSTRING([MVDocument temporaryDirectory]),
                                           CSTRING([[[dataController fileName] lastPathComponent] stringByAppendingString:@"."])));

    archiver = [MVArchiver archiverWithPath:swapPath];
  }
  return self;
}

//-----------------------------------------------------------------------------
- (NSString *)description
{
  return [[super description] stringByAppendingFormat:@" [%@]",rootNode.caption];
}

//-----------------------------------------------------------------------------
-(void)printException:(NSException *)exception caption:(NSString *)caption
{
  @synchronized([NSApp class])
  {
    NSLog(@"%@: Exception (%@): %@", self, caption, [exception name]);
    NSLog(@"  Reason: %@", [exception reason]);
    NSLog(@"  User Info: %@", [exception userInfo]);
    NSLog(@"  Backtrace:\n%@", [exception callStackSymbols]);
  }
}

//-----------------------------------------------------------------------------
- (BOOL)is64bit
{
  return NO;
}

//-----------------------------------------------------------------------------
- (void)doMainTasks
{
}

//-----------------------------------------------------------------------------
- (void)doBackgroundTasks
{
  [archiver halt];
}

//-----------------------------------------------------------------------------
- (NSString *)convertToRVA: (NSString *)offsetStr
{
  return @"";
}

//-----------------------------------------------------------------------------
// Depth-first Traversal of nodes
//-----------------------------------------------------------------------------
- (MVNode *)findNodeByUserInfo:(NSDictionary *)userInfo
{
  [dataController.treeLock lock];
  MVNode * node = [rootNode findNodeByUserInfo:userInfo];
  [dataController.treeLock unlock];
  
  return node;
}

//-----------------------------------------------------------------------------
// Create data node without details table (only hex content)
//-----------------------------------------------------------------------------
- (MVNode *)createDataNode:(MVNode *)parent
                   caption:(NSString *)caption
                  location:(uint32_t)location
                    length:(uint32_t)length
{
  MVNode * node = [parent insertChild:caption location:location length:length];
  return node;
}

@end
