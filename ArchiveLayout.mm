/*
 *  ArchiveLayout.mm
 *  MachOView
 *
 *  Created by psaghelyi on 18/03/2011.
 *
 */

#include <string>
#include <vector>
#include <set>
#include <map>
#include <cxxabi.h>

#import "Common.h"
#import "ArchiveLayout.h"
#import "DataController.h"
#import "MachOLayout.h"
#import "ReadWrite.h"

//============================================================================
@implementation MVObjectInfo

@synthesize name, length, layout;

//-----------------------------------------------------------------------------
-(id)initWithName:(NSString *)_name Length:(uint32_t)_length
{
  if (self = [super init])
  {
    name = _name;
    length = _length;
  }
  return self;
}

//-----------------------------------------------------------------------------
+(MVObjectInfo *)objectInfoWithName:(NSString *)name Length:(uint32_t)length
{
  return [[MVObjectInfo alloc] initWithName:name Length:length];
}

@end

//============================================================================
@implementation ArchiveLayout

- (id)initWithDataController:(MVDataController *)dc rootNode:(MVNode *)node
{
  if (self = [super initWithDataController:dc rootNode:node])
  {
    objectInfoMap = [[NSMutableDictionary alloc] init];
  }
  return self;
}
//-----------------------------------------------------------------------------

+ (ArchiveLayout *)layoutWithDataController:(MVDataController *)dc rootNode:(MVNode *)node
{
  return [[ArchiveLayout alloc] initWithDataController:dc rootNode:node];
}
//-----------------------------------------------------------------------------

- (MVNode *)createSignatureNode:(MVNode *)parent
                        caption:(NSString *)caption
                       location:(uint32_t)location
                         length:(uint32_t)length
{
  MVNodeSaver nodeSaver;
  MVNode * node = [parent insertChildWithDetails:caption location:location length:length saver:nodeSaver]; 
  
  NSRange range = NSMakeRange(location,0);
  NSString * lastReadHex;
  
  NSString * signature = [dataController read_string:range fixlen:8 lastReadHex:&lastReadHex];
  [node.details appendRow:[NSString stringWithFormat:@"%.8lX", range.location]
                         :lastReadHex
                         :@"Signature"
                         :signature];
  return node;
}
//----------------------------------------------------------------------------

- (MVNode *)createHeaderNode:(MVNode *)parent
                     caption:(NSString *)caption
                    location:(uint32_t)location
                      length:(uint32_t)length
{
  MVNodeSaver nodeSaver;
  MVNode * node = [parent insertChildWithDetails:caption location:location length:length saver:nodeSaver]; 
  
  NSRange range = NSMakeRange(location,0);
  NSString * lastReadHex;
  
  NSString * name = [dataController read_string:range fixlen:16 lastReadHex:&lastReadHex];
  [node.details appendRow:[NSString stringWithFormat:@"%.8lX", range.location]
                         :lastReadHex
                         :@"Name"
                         :name];
  
  NSString * time_str = [dataController read_string:range fixlen:12 lastReadHex:&lastReadHex];
  time_t time = (time_t)[time_str longLongValue];
  [node.details appendRow:[NSString stringWithFormat:@"%.8lX", range.location]
                         :lastReadHex
                         :@"Time Stamp"
                         :[NSString stringWithFormat:@"%s", ctime(&time)]];

  NSString * user_id_str = [dataController read_string:range fixlen:6 lastReadHex:&lastReadHex];
  [node.details appendRow:[NSString stringWithFormat:@"%.8lX", range.location]
                         :lastReadHex
                         :@"UserID"
                         :[NSString stringWithFormat:@"%u",[user_id_str intValue]]];

  NSString * group_id_str = [dataController read_string:range fixlen:6 lastReadHex:&lastReadHex];
  [node.details appendRow:[NSString stringWithFormat:@"%.8lX", range.location]
                         :lastReadHex
                         :@"GroupID"
                         :[NSString stringWithFormat:@"%u",[group_id_str intValue]]];

  NSString * mode_str = [dataController read_string:range fixlen:8 lastReadHex:&lastReadHex];
  [node.details appendRow:[NSString stringWithFormat:@"%.8lX", range.location]
                         :lastReadHex
                         :@"Mode"
                         :[NSString stringWithFormat:@"%u",[mode_str intValue]]];

  NSString * size_str = [dataController read_string:range fixlen:8 lastReadHex:&lastReadHex];
  [node.details appendRow:[NSString stringWithFormat:@"%.8lX", range.location]
                         :lastReadHex
                         :@"Size"
                         :[NSString stringWithFormat:@"%u",[size_str intValue]]];
  
  // read spaces until end-of-header (0x60 0x0A)
  NSMutableString * mutableLastReadHex = [[NSMutableString alloc] initWithCapacity:2];
  NSMutableString * padding = [[NSMutableString alloc] initWithCapacity:2];
  for(;;) 
  {
    [padding appendString:[dataController read_string:range fixlen:1 lastReadHex:&lastReadHex]];
    [mutableLastReadHex appendString:lastReadHex];
    if (*(CSTRING(padding) + [padding length] - 1) != ' ')
    {
      [padding appendString:[dataController read_string:range fixlen:1 lastReadHex:&lastReadHex]];
      [mutableLastReadHex appendString:lastReadHex];
      break;
    }
  }
  [node.details appendRow:[NSString stringWithFormat:@"%.8lX", range.location - [padding length] + 2]
                         :mutableLastReadHex
                         :@"End Header"
                         :padding];
  
  MVObjectInfo * objectInfo;
  if (NSEqualRanges([name rangeOfString:@"#1/"], NSMakeRange(0,3)))
  {
    uint32_t len = [[name substringFromIndex:3] intValue];
    NSString * long_name = [dataController read_string:range fixlen:len lastReadHex:&lastReadHex];
    [node.details appendRow:[NSString stringWithFormat:@"%.8lX", range.location]
                           :lastReadHex
                           :@"Long Name"
                           :long_name];
    
    objectInfo = [MVObjectInfo objectInfoWithName:long_name Length:[size_str intValue] - len];
  }
  else 
  {
    objectInfo = [MVObjectInfo objectInfoWithName:name Length:[size_str intValue]];
  }
  [objectInfoMap setObject:objectInfo forKey:[NSNumber numberWithUnsignedLong:location]];
  
  node.dataRange = NSMakeRange(location, NSMaxRange(range) - location);
  
  return node;
}
//----------------------------------------------------------------------------

- (MVNode *)createMemberNode:(MVNode *)parent
                     caption:(NSString *)caption
                    location:(uint32_t)location
                      length:(uint32_t)length
                      strtab:(char const *)strtab
{
  MVNodeSaver nodeSaver;
  MVNode * node = [parent insertChildWithDetails:caption location:location length:length saver:nodeSaver]; 
  
  NSRange range = NSMakeRange(location,0);
  NSString * lastReadHex;
  
  uint32_t size = [dataController read_uint32:range lastReadHex:&lastReadHex];
  [node.details appendRow:[NSString stringWithFormat:@"%.8lX", range.location]
                         :lastReadHex
                         :@"Size"
                         :[NSString stringWithFormat:@"%u",size]];
  
  [node.details setAttributes:MVCellColorAttributeName,[NSColor greenColor],
                              MVUnderlineAttributeName,@"YES",nil];
  
  node.dataRange = NSMakeRange(location, size);
  
  while (size > 0)
  {
    uint32_t strx = [dataController read_uint32:range lastReadHex:&lastReadHex];
    
    // accumulate search info
    NSUInteger bookmark = node.details.rowCount;
    NSString * symbolName = [NSString stringWithFormat:@"%s",strtab + strx];
    
    [node.details appendRow:[NSString stringWithFormat:@"%.8lX", range.location]
                           :lastReadHex
                           :@"Symbol"
                           :symbolName];

    uint32_t off = [dataController read_uint32:range lastReadHex:&lastReadHex];
    
    MVObjectInfo * objectInfo = [objectInfoMap objectForKey:[NSNumber numberWithUnsignedLong:off + imageOffset]];
    
    [node.details appendRow:[NSString stringWithFormat:@"%.8lX", range.location]
                           :lastReadHex
                           :@"Object"
                           :objectInfo.name];
    
    [node.details setAttributesFromRowIndex:bookmark:MVMetaDataAttributeName,symbolName,nil];
    [node.details setAttributes:MVUnderlineAttributeName,@"YES",nil];
    
    size -= sizeof(struct ranlib);
  }
  
  return node;
}


//----------------------------------------------------------------------------


- (void)doMainTasks
{
  NSString * lastReadHex;
  
  // archive start signature
  [self createSignatureNode:rootNode 
                    caption:@"Start" 
                   location:imageOffset 
                     length:8];
  

  // read symbol table (ranlibs)
  MVNode * symtabHeaderNode = [self createHeaderNode:rootNode 
                                             caption:@"Symtab Header"
                                            location:imageOffset + 8 
                                              length:0]; // length will be determined in function
  
  // skip symbol and string table for now
  uint32_t symtabOffset = NSMaxRange(symtabHeaderNode.dataRange);
  NSRange range = NSMakeRange(symtabOffset,0);
  uint32_t symtabSize = [dataController read_uint32:range lastReadHex:&lastReadHex] + sizeof(uint32_t);
  uint32_t strtabOffset = symtabOffset + symtabSize;
  range = NSMakeRange(strtabOffset,0);  
  uint32_t strtabSize = [dataController read_uint32:range lastReadHex:&lastReadHex] + sizeof(uint32_t);
  
  // read headers

  for (uint32_t location = strtabOffset + strtabSize; location < NSMaxRange(rootNode.dataRange); )
  {
    MVNode * headerNode = [self createHeaderNode:rootNode 
                                         caption:@"Object Header"
                                        location:location 
                                          length:0]; // length will be determined in function
    
    MVObjectInfo * objectInfo = [objectInfoMap objectForKey:[NSNumber numberWithUnsignedLong:location]];
    
    uint32_t objectOffset = NSMaxRange(headerNode.dataRange); // starts right after the header
    uint32_t objectSize = objectInfo.length;
    
    // create Mach-O object layout
    MVNode * objectNode = [self createDataNode:rootNode 
                                       caption:objectInfo.name
                                      location:objectOffset 
                                        length:objectSize];
    
    objectInfo.layout = [MachOLayout layoutWithDataController:dataController rootNode:objectNode];
    
    [objectNode.userInfo setObject:objectInfo.layout forKey:MVLayoutUserInfoKey];
    [objectInfo.layout doMainTasks];
    
    // move to the next header
    location = objectOffset + objectSize;
  }

  // finish symbol table based on the information about processed objects
  [self createMemberNode:rootNode 
                 caption:@"Symbol Table"
                location:symtabOffset
                  length:symtabSize
                  strtab:(char *)((uint8_t *)[dataController.fileData bytes] + strtabOffset + sizeof(uint32_t))]; 
  
  [self createDataNode:rootNode caption:@"String Table" 
              location:strtabOffset 
                length:strtabSize];
  

  [super doMainTasks];
}
//----------------------------------------------------------------------------

- (void)doBackgroundTasks
{
  [dataController updateStatus:MVStatusTaskStarted];
  
  for (MVObjectInfo * objectInfo in [objectInfoMap allValues])
  {
    MVLayout * layout = objectInfo.layout;
    
    // if the thread is cancelled, then the MVLayout::doBackgroundTasks will not been called
    // so, here is the only chance to stop the saver thread for the particular layout
    if ([backgroundThread isCancelled])
    {
      [layout.archiver halt];
      continue;
    }

    // the MVLayout::doBackgroundTasks is called before this returns
    [layout doBackgroundTasks];
  }
  
  [super doBackgroundTasks];
  
  [dataController updateStatus:MVStatusTaskTerminated];
}
//----------------------------------------------------------------------------

@end
