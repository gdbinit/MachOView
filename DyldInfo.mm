/*
 *  DyldInfo.mm
 *  MachOView
 *
 *  Created by psaghelyi on 21/09/2010.
 *
 */

#include <string>
#include <vector>
#include <set>
#include <map>

#import "Common.h"
#import "DyldInfo.h"
#import "ReadWrite.h"
#import "DataController.h"

using namespace std;


//============================================================================
@implementation DyldHelper

//-----------------------------------------------------------------------------
-(id) initWithSymbols:(NSDictionary *)symbolNames is64Bit:(bool)is64Bit
{
  if (self = [super init])
  {
    externalMap = [[NSMutableDictionary alloc] initWithCapacity:[symbolNames count]];
    
    NSEnumerator * enumerator = [symbolNames keyEnumerator];
    id key;
    while ((key = [enumerator nextObject]) != nil) 
    {
      NSNumber * symbolIndex = (NSNumber *)key;
      // negative index indicates that it is external
      if ((is64Bit == NO && (int32_t)[symbolIndex unsignedLongValue] < 0) ||
          (int64_t)[symbolIndex unsignedLongLongValue] < 0)
      {
        [externalMap setObject:key forKey:[symbolNames objectForKey:key]];
      }
    }
  }
  return self;
}

//-----------------------------------------------------------------------------
+(DyldHelper *) dyldHelperWithSymbols:(NSDictionary *)symbolNames is64Bit:(bool)is64Bit
{
  return [[DyldHelper alloc] initWithSymbols:symbolNames is64Bit:is64Bit];
}

//-----------------------------------------------------------------------------
-(NSNumber *) indexForSymbol:(NSString *)symbolName
{
  return [externalMap objectForKey:symbolName];
}

@end


//============================================================================
@implementation MachOLayout (DyldInfo)


//-----------------------------------------------------------------------------
- (void)rebaseAddress:(uint64_t)address 
                 type:(uint32_t)type 
                 node:(MVNode *)node
             location:(uint32_t)location
{
  NSString * descStr = [NSString stringWithFormat:@"%@ 0x%qX %@",
                        [self is64bit] == NO ? [self findSectionContainsRVA:address] : [self findSectionContainsRVA64:address],
                        address,
                        type == REBASE_TYPE_POINTER ? @"Pointer" :
                        type == REBASE_TYPE_TEXT_ABSOLUTE32 ? @"Abs32  " :
                        type == REBASE_TYPE_TEXT_PCREL32 ? @"PCrel32" : @"???"];
  
  [node.details appendRow:[NSString stringWithFormat:@"%.8X", location]
                         :@""
                         :descStr
                         :@""];
}

//-----------------------------------------------------------------------------
- (MVNode *)createRebaseNode:(MVNode *)parent
                     caption:(NSString *)caption
                    location:(uint32_t)location
                      length:(uint32_t)length
                 baseAddress:(uint64_t)baseAddress
{
  MVNode * dataNode = [self createDataNode:parent 
                                   caption:caption 
                                  location:location 
                                    length:length];

  MVNodeSaver nodeSaver;
  MVNode * node = [dataNode insertChildWithDetails:@"Opcodes" location:location length:length saver:nodeSaver];
  
  MVNodeSaver actionNodeSaver;
  MVNode * actionNode = [dataNode insertChildWithDetails:@"Actions" location:location length:length saver:actionNodeSaver];
  
  NSRange range = NSMakeRange(location,0);
  NSString * lastReadHex;  

  BOOL isDone = NO;
  
  uint64_t ptrSize = ([self is64bit] == NO ? sizeof(uint32_t) : sizeof(uint64_t));
  uint64_t address = baseAddress;
  uint32_t type = 0;
  
  uint32_t doRebaseLocation = location;
  
  while (NSMaxRange(range) < location + length && isDone == NO)
  {
    uint8_t byte = [dataController read_int8:range lastReadHex:&lastReadHex];
    uint8_t opcode = byte & REBASE_OPCODE_MASK;
    uint8_t immediate = byte & REBASE_IMMEDIATE_MASK;
    
    switch (opcode) 
    {
      case REBASE_OPCODE_DONE:
        isDone = YES;

        [node.details appendRow:[NSString stringWithFormat:@"%.8lX", range.location]
                               :lastReadHex
                               :@"REBASE_OPCODE_DONE"
                               :@""];
        break;
        
      case REBASE_OPCODE_SET_TYPE_IMM:
        {
            type = immediate;
            NSString *typeString = [NSString alloc];
            switch (type)
            {
                case REBASE_TYPE_POINTER:
                    typeString = [typeString initWithString:@"REBASE_TYPE_POINTER"];
                    break;
                case REBASE_TYPE_TEXT_ABSOLUTE32:
                    typeString  = [typeString initWithString:@"REBASE_TYPE_TEXT_ABSOLUTE32"];
                    break;
                case REBASE_TYPE_TEXT_PCREL32:
                    typeString = [typeString initWithString:@"REBASE_TYPE_TEXT_PCREL32"];
                    break;
                default:
                    typeString = [typeString initWithString:@"Unknown"];
            }
            
            [node.details appendRow:[NSString stringWithFormat:@"%.8lX", range.location]
                                   :lastReadHex
                                   :@"REBASE_OPCODE_SET_TYPE_IMM"
                                   :[NSString stringWithFormat:@"type (%i, %@)", type, typeString]];
            break;
        }
      case REBASE_OPCODE_SET_SEGMENT_AND_OFFSET_ULEB: 
      {
        uint32_t segmentIndex = immediate;
        
        [node.details appendRow:[NSString stringWithFormat:@"%.8lX", range.location]
                               :lastReadHex
                               :@"REBASE_OPCODE_SET_SEGMENT_AND_OFFSET_ULEB"
                               :[NSString stringWithFormat:@"segment (%u)", segmentIndex]];
         
        uint64_t offset = [dataController read_uleb128:range lastReadHex:&lastReadHex];
        
        [node.details appendRow:[NSString stringWithFormat:@"%.8lX", range.location]
                               :lastReadHex
                               :@"uleb128"
                               :[NSString stringWithFormat:@"offset (%qi)",offset]];
        
        if (([self is64bit] == NO && segmentIndex >= segments.size()) || 
            ([self is64bit] == YES && segmentIndex >= segments_64.size())) 
        {
          [NSException raise:@"Segment"
                      format:@"index is out of range %u", segmentIndex];
        }
        
        address = ([self is64bit] == NO ? segments.at(segmentIndex)->vmaddr 
                                        : segments_64.at(segmentIndex)->vmaddr) + offset;
      } break;
        
      case REBASE_OPCODE_ADD_ADDR_ULEB: 
      {
        [node.details appendRow:[NSString stringWithFormat:@"%.8lX", range.location]
                               :lastReadHex
                               :@"REBASE_OPCODE_ADD_ADDR_ULEB"
                               :@""];
         
        uint64_t offset = [dataController read_uleb128:range lastReadHex:&lastReadHex];
        
        [node.details appendRow:[NSString stringWithFormat:@"%.8lX", range.location]
                               :lastReadHex
                               :@"uleb128"
                               :[NSString stringWithFormat:@"offset (%qi)",offset]];
        
        address += offset;
      } break;
        
      case REBASE_OPCODE_ADD_ADDR_IMM_SCALED:
      {
        uint32_t scale = immediate;
        
        [node.details appendRow:[NSString stringWithFormat:@"%.8lX", range.location]
                               :lastReadHex
                               :@"REBASE_OPCODE_ADD_ADDR_IMM_SCALED"
                               :[NSString stringWithFormat:@"scale (%u)",scale]];
        
        address += scale * ptrSize;
      } break;
        
      case REBASE_OPCODE_DO_REBASE_IMM_TIMES: 
      {
        uint32_t count = immediate;
        
        [node.details appendRow:[NSString stringWithFormat:@"%.8lX", range.location]
                               :lastReadHex
                               :@"REBASE_OPCODE_DO_REBASE_IMM_TIMES"
                               :[NSString stringWithFormat:@"count (%u)",count]];

        [node.details setAttributes:MVUnderlineAttributeName,@"YES",nil];
        
        for (uint32_t index = 0; index < count; index++) 
        {
          [self rebaseAddress:address type:type node:actionNode location:doRebaseLocation];
          address += ptrSize;
        }
        
        doRebaseLocation = NSMaxRange(range);
        
      } break;
        
      case REBASE_OPCODE_DO_REBASE_ULEB_TIMES: 
      {
        [node.details appendRow:[NSString stringWithFormat:@"%.8lX", range.location]
                               :lastReadHex
                               :@"REBASE_OPCODE_DO_REBASE_ULEB_TIMES"
                               :@""];
        
        uint32_t startNextRebase = NSMaxRange(range);
        
        uint64_t count = [dataController read_uleb128:range lastReadHex:&lastReadHex];
        [node.details appendRow:[NSString stringWithFormat:@"%.8lX", range.location]
                               :lastReadHex
                               :@"uleb128"
                               :[NSString stringWithFormat:@"count (%qu)",count]];
        
        [node.details setAttributes:MVUnderlineAttributeName,@"YES",nil];
        
        for (uint64_t index = 0; index < count; index++) 
        {
          [self rebaseAddress:address type:type node:actionNode location:doRebaseLocation];
          address += ptrSize;
        }
        
        doRebaseLocation = startNextRebase;
        
      } break;
        
      case REBASE_OPCODE_DO_REBASE_ADD_ADDR_ULEB: 
      {
        [node.details appendRow:[NSString stringWithFormat:@"%.8lX", range.location]
                               :lastReadHex
                               :@"REBASE_OPCODE_DO_REBASE_ADD_ADDR_ULEB"
                               :@""];
        
        uint32_t startNextRebase = NSMaxRange(range);
        
        uint64_t offset = [dataController read_uleb128:range lastReadHex:&lastReadHex];
        [node.details appendRow:[NSString stringWithFormat:@"%.8lX", range.location]
                               :lastReadHex
                               :@"uleb128"
                               :[NSString stringWithFormat:@"offset (%qi)",offset]];
        
        [node.details setAttributes:MVUnderlineAttributeName,@"YES",nil];
        
        [self rebaseAddress:address type:type node:actionNode location:doRebaseLocation];
        address += ptrSize + offset;
        
        doRebaseLocation = startNextRebase;
        
      } break;
        
      case REBASE_OPCODE_DO_REBASE_ULEB_TIMES_SKIPPING_ULEB: 
      {
        [node.details appendRow:[NSString stringWithFormat:@"%.8lX", range.location]
                               :lastReadHex
                               :@"REBASE_OPCODE_DO_REBASE_ULEB_TIMES_SKIPPING_ULEB"
                               :@""];
        
        uint32_t startNextRebase = NSMaxRange(range);
        
        uint64_t count = [dataController read_uleb128:range lastReadHex:&lastReadHex];
        [node.details appendRow:[NSString stringWithFormat:@"%.8lX", range.location]
                               :lastReadHex
                               :@"uleb128"
                               :[NSString stringWithFormat:@"count (%qu)",count]];

        uint64_t skip = [dataController read_uleb128:range lastReadHex:&lastReadHex];
        [node.details appendRow:[NSString stringWithFormat:@"%.8lX", range.location]
                               :lastReadHex
                               :@"uleb128"
                               :[NSString stringWithFormat:@"skip (%qu)",skip]];

        [node.details setAttributes:MVUnderlineAttributeName,@"YES",nil];
        
        for (uint64_t index = 0; index < count; index++) 
        {
          [self rebaseAddress:address type:type node:actionNode location:doRebaseLocation];
          address += ptrSize + skip;
        }
        
        doRebaseLocation = startNextRebase;
        
      } break;
        
      default:
        [NSException raise:@"Rebase info" format:@"Unknown opcode (%u %u)", 
         ((uint32_t)-1 & opcode), ((uint32_t)-1 & immediate)];
    }
  }
  
  return node;
}


//-----------------------------------------------------------------------------
//-----------------------------------------------------------------------------
//-----------------------------------------------------------------------------



//-----------------------------------------------------------------------------
- (void)bindAddress:(uint64_t)address 
               type:(uint32_t)type 
         symbolName:(NSString *)symbolName 
              flags:(uint32_t)flags
             addend:(int64_t)addend 
     libraryOrdinal:(int32_t)libOrdinal
               node:(MVNode *)node
           nodeType:(BindNodeType)nodeType
           location:(uint32_t)location
         dyldHelper:(DyldHelper *)helper
            ptrSize:(uint32_t)ptrSize
{
  NSString * descStr = [NSString stringWithFormat:@"%@ 0x%qX", 
                        [self is64bit] == NO ? [self findSectionContainsRVA:address] : [self findSectionContainsRVA64:address],
                        address];
  
  if (nodeType != NodeTypeLazyBind)
  {
    descStr = [descStr stringByAppendingFormat:@" %@ addend:%qi",
               type == BIND_TYPE_POINTER ? @"Pointer" :
               type == BIND_TYPE_TEXT_ABSOLUTE32 ? @"Abs32  " :
               type == BIND_TYPE_TEXT_PCREL32 ? @"PCrel32" : @"type:???",
               addend];
  }
  
  if ((flags & BIND_SYMBOL_FLAGS_WEAK_IMPORT) != 0)
  {
    descStr = [descStr stringByAppendingString:@"[weak-ref]"];
  }
  if ((flags & BIND_SYMBOL_FLAGS_NON_WEAK_DEFINITION) != 0)
  {
    descStr = [descStr stringByAppendingString:@"[strong-def]"];
  }
   
  if (nodeType != NodeTypeWeakBind)
  {
    struct dylib const * dylib = [self getDylibByIndex:libOrdinal];
    
    descStr = [descStr stringByAppendingFormat:@" (%@)", 
               libOrdinal == BIND_SPECIAL_DYLIB_SELF ? @"BIND_SPECIAL_DYLIB_SELF" :
               libOrdinal == BIND_SPECIAL_DYLIB_MAIN_EXECUTABLE ? @"BIND_SPECIAL_DYLIB_MAIN_EXECUTABLE" :
               libOrdinal == BIND_SPECIAL_DYLIB_FLAT_LOOKUP ? @"BIND_SPECIAL_DYLIB_FLAT_LOOKUP" :
               (uint32_t)libOrdinal >= dylibs.size() ? @"???" :
                 [NSSTRING((uint8_t *)dylib + dylib->name.offset - sizeof(struct load_command)) lastPathComponent]];
  }
  
  [node.details appendRow:[NSString stringWithFormat:@"%.8X", location]
                         :@""
                         :descStr
                         :symbolName];

  [node.details setAttributes:MVMetaDataAttributeName,symbolName,nil];
  
  // preserve binding info for reloc pathcing
  if ([self isDylibStub] == NO && nodeType == NodeTypeBind) // weak and lazy does not count
  {
    NSParameterAssert(type == BIND_TYPE_POINTER); // only this one is supported so far
    NSNumber * symbolIndex = [helper indexForSymbol:symbolName];
    if (symbolIndex != nil)
    {
      uint32_t relocLocation;
      uint64_t relocValue;
      if ([self is64bit] == NO)
      {
        relocLocation = [self RVAToFileOffset:(uint32_t)address];
        relocValue = [symbolIndex longValue];
      }
      else
      {
        relocLocation = [self RVA64ToFileOffset:address];
        relocValue = [symbolIndex longLongValue];
      }
      
      // update real data
      relocValue += addend;
      [dataController.realData replaceBytesInRange:NSMakeRange(relocLocation, ptrSize) withBytes:&relocValue];
      
      /*
        NSLog(@"%0xqX --> %0xqX", 
              ([self is64bit] == NO ? [self fileOffsetToRVA:relocLocation] : [self fileOffsetToRVA64:relocLocation]),
              relocValue);
       */
    }
  }
}
//-----------------------------------------------------------------------------
      
- (MVNode *)createBindingNode:(MVNode *)parent
                      caption:(NSString *)caption
                     location:(uint32_t)location
                       length:(uint32_t)length
                  baseAddress:(uint64_t)baseAddress
                     nodeType:(BindNodeType)nodeType
                   dyldHelper:(DyldHelper *)helper
{
  MVNode * dataNode = [self createDataNode:parent 
                                   caption:caption 
                                  location:location 
                                    length:length];
  
  MVNodeSaver nodeSaver;
  MVNode * node = [dataNode insertChildWithDetails:@"Opcodes" location:location length:length saver:nodeSaver];
  
  MVNodeSaver actionNodeSaver;
  MVNode * actionNode = [dataNode insertChildWithDetails:@"Actions" location:location length:length saver:actionNodeSaver];
  
  NSRange range = NSMakeRange(location,0);
  NSString * lastReadHex;

  //----------------------------
  
  BOOL isDone = NO;
  
  int32_t libOrdinal = 0;
  uint32_t type = 0;
  int64_t addend = 0;
  NSString * symbolName = nil;
  uint32_t symbolFlags = 0;
  
  uint32_t doBindLocation = location;
  
  uint64_t ptrSize = ([self is64bit] == NO ? sizeof(uint32_t) : sizeof(uint64_t));
  uint64_t address = baseAddress;
  
  while (NSMaxRange(range) < location + length && isDone == NO)
  {
    uint8_t byte = [dataController read_int8:range lastReadHex:&lastReadHex];
    uint8_t opcode = byte & BIND_OPCODE_MASK;
    uint8_t immediate = byte & BIND_IMMEDIATE_MASK;
    
    switch (opcode) 
    {
      case BIND_OPCODE_DONE:
        [node.details appendRow:[NSString stringWithFormat:@"%.8lX", range.location]
                               :lastReadHex
                               :@"BIND_OPCODE_DONE"
                               :@""];
        
        // The lazy bindings have one of these at the end of each bind.
        if (nodeType != NodeTypeLazyBind)
        {
          isDone = YES;
        }
        
        doBindLocation = NSMaxRange(range);
        
        break;
        
      case BIND_OPCODE_SET_DYLIB_ORDINAL_IMM:
        libOrdinal = immediate;
        [node.details appendRow:[NSString stringWithFormat:@"%.8lX", range.location]
                               :lastReadHex
                               :@"BIND_OPCODE_SET_DYLIB_ORDINAL_IMM"
                               :[NSString stringWithFormat:@"dylib (%d)",libOrdinal]];
        break;
        
      case BIND_OPCODE_SET_DYLIB_ORDINAL_ULEB:
        [node.details appendRow:[NSString stringWithFormat:@"%.8lX", range.location]
                               :lastReadHex
                               :@"BIND_OPCODE_SET_DYLIB_ORDINAL_ULEB"
                               :@""];
        
        libOrdinal = [dataController read_uleb128:range lastReadHex:&lastReadHex];
        
        [node.details appendRow:[NSString stringWithFormat:@"%.8lX", range.location]
                               :lastReadHex
                               :@"uleb128"
                               :[NSString stringWithFormat:@"dylib (%d)",libOrdinal]];
        break;
        
      case BIND_OPCODE_SET_DYLIB_SPECIAL_IMM: 
      {
        // Special means negative
        if (immediate == 0)
        {
          libOrdinal = 0;
        }
        else 
        {
          int8_t signExtended = immediate | BIND_OPCODE_MASK; // This sign extends the value
          
          libOrdinal = signExtended;
        }
        [node.details appendRow:[NSString stringWithFormat:@"%.8lX", range.location]
                               :lastReadHex
                               :@"BIND_OPCODE_SET_DYLIB_SPECIAL_IMM"
                               :[NSString stringWithFormat:@"dylib (%d)",libOrdinal]];
      } break;
        
      case BIND_OPCODE_SET_SYMBOL_TRAILING_FLAGS_IMM:
        symbolFlags = immediate;
        [node.details appendRow:[NSString stringWithFormat:@"%.8lX", range.location]
                               :lastReadHex
                               :@"BIND_OPCODE_SET_SYMBOL_TRAILING_FLAGS_IMM"
                               :[NSString stringWithFormat:@"flags (%u)",((uint32_t)-1 & symbolFlags)]];
        
        symbolName = [dataController read_string:range lastReadHex:&lastReadHex];
        [node.details appendRow:[NSString stringWithFormat:@"%.8lX", range.location]
                               :lastReadHex
                               :@"string"
                               :[NSString stringWithFormat:@"name (%@)",symbolName]];
        break;
        
      case BIND_OPCODE_SET_TYPE_IMM:
        type = immediate;
        [node.details appendRow:[NSString stringWithFormat:@"%.8lX", range.location]
                               :lastReadHex
                               :@"BIND_OPCODE_SET_TYPE_IMM"
                               :[NSString stringWithFormat:@"type (%@)",
                                 type == BIND_TYPE_POINTER ? @"BIND_TYPE_POINTER" :
                                 type == BIND_TYPE_TEXT_ABSOLUTE32 ? @"BIND_TYPE_TEXT_ABSOLUTE32" :
                                 type == BIND_TYPE_TEXT_PCREL32 ? @"BIND_TYPE_TEXT_PCREL32" : @"???"]];
        break;
        
      case BIND_OPCODE_SET_ADDEND_SLEB:
        [node.details appendRow:[NSString stringWithFormat:@"%.8lX", range.location]
                               :lastReadHex
                               :@"BIND_OPCODE_SET_ADDEND_SLEB"
                               :@""];
        
        addend = [dataController read_sleb128:range lastReadHex:&lastReadHex];
        [node.details appendRow:[NSString stringWithFormat:@"%.8lX", range.location]
                               :lastReadHex
                               :@"sleb128"
                               :[NSString stringWithFormat:@"addend (%qi)",addend]];
        break;
        
      case BIND_OPCODE_SET_SEGMENT_AND_OFFSET_ULEB: 
      {
        uint32_t segmentIndex = immediate;
        
        [node.details appendRow:[NSString stringWithFormat:@"%.8lX", range.location]
                               :lastReadHex
                               :@"BIND_OPCODE_SET_SEGMENT_AND_OFFSET_ULEB"
                               :[NSString stringWithFormat:@"segment (%u)",segmentIndex]];
        
        uint64_t val = [dataController read_uleb128:range lastReadHex:&lastReadHex];
        
        [node.details appendRow:[NSString stringWithFormat:@"%.8lX", range.location]
                               :lastReadHex
                               :@"uleb128"
                               :[NSString stringWithFormat:@"offset (%qi)",val]];
        
        if (([self is64bit] == NO && segmentIndex >= segments.size()) || 
            ([self is64bit] == YES && segmentIndex >= segments_64.size())) 
        {
          [NSException raise:@"Segment"
                      format:@"index is out of range %u", segmentIndex];
        }
        
        address = ([self is64bit] == NO ? segments.at(segmentIndex)->vmaddr 
                                        : segments_64.at(segmentIndex)->vmaddr) + val;
      } break;
        
      case BIND_OPCODE_ADD_ADDR_ULEB: 
      {
        [node.details appendRow:[NSString stringWithFormat:@"%.8lX", range.location]
                               :lastReadHex
                               :@"BIND_OPCODE_ADD_ADDR_ULEB"
                               :@""];
        
        uint64_t val = [dataController read_uleb128:range lastReadHex:&lastReadHex];
        
        [node.details appendRow:[NSString stringWithFormat:@"%.8lX", range.location]
                               :lastReadHex
                               :@"uleb128"
                               :[NSString stringWithFormat:@"offset (%qi)",val]];

        address += val;
      } break;
        
      case BIND_OPCODE_DO_BIND:
      {
        [node.details appendRow:[NSString stringWithFormat:@"%.8lX", range.location]
                               :lastReadHex
                               :@"BIND_OPCODE_DO_BIND"
                               :@""];
        
        [node.details setAttributes:MVUnderlineAttributeName,@"YES",nil];
        
        [self bindAddress:address 
                     type:type 
               symbolName:symbolName 
                    flags:symbolFlags 
                   addend:addend 
           libraryOrdinal:libOrdinal 
                     node:actionNode
                 nodeType:nodeType
                 location:doBindLocation
               dyldHelper:helper
                  ptrSize:ptrSize];
        
        doBindLocation = NSMaxRange(range);
        
        address += ptrSize;
      } break;
        
      case BIND_OPCODE_DO_BIND_ADD_ADDR_ULEB: 
      {
        [node.details appendRow:[NSString stringWithFormat:@"%.8lX", range.location]
                               :lastReadHex
                               :@"BIND_OPCODE_DO_BIND_ADD_ADDR_ULEB"
                               :@""];

        uint32_t startNextBind = NSMaxRange(range);
        
        uint64_t val = [dataController read_uleb128:range lastReadHex:&lastReadHex];
        [node.details appendRow:[NSString stringWithFormat:@"%.8lX", range.location]
                               :lastReadHex
                               :@"uleb128"
                               :[NSString stringWithFormat:@"offset (%qi)",val]];
        
        [node.details setAttributes:MVUnderlineAttributeName,@"YES",nil];
        
        [self bindAddress:address 
                     type:type 
               symbolName:symbolName 
                    flags:symbolFlags 
                   addend:addend 
           libraryOrdinal:libOrdinal 
                     node:actionNode
                 nodeType:nodeType
                 location:doBindLocation
               dyldHelper:helper
                  ptrSize:ptrSize];
        
        doBindLocation = startNextBind;
        
        address += ptrSize + val;
      } break;
        
      case BIND_OPCODE_DO_BIND_ADD_ADDR_IMM_SCALED:
      {
        uint32_t scale = immediate;
        
        [node.details appendRow:[NSString stringWithFormat:@"%.8lX", range.location]
                               :lastReadHex
                               :@"BIND_OPCODE_DO_BIND_ADD_ADDR_IMM_SCALED"
                               :[NSString stringWithFormat:@"scale (%u)",scale]];
        
        [node.details setAttributes:MVUnderlineAttributeName,@"YES",nil];
        
        [self bindAddress:address 
                     type:type 
               symbolName:symbolName 
                    flags:symbolFlags 
                   addend:addend 
           libraryOrdinal:libOrdinal 
                     node:actionNode
                 nodeType:nodeType
                 location:doBindLocation
               dyldHelper:helper
                  ptrSize:ptrSize];
        
        doBindLocation = NSMaxRange(range);
        
        address += ptrSize + scale * ptrSize;
      } break;
        
      case BIND_OPCODE_DO_BIND_ULEB_TIMES_SKIPPING_ULEB: 
      {
        [node.details appendRow:[NSString stringWithFormat:@"%.8lX", range.location]
                               :lastReadHex
                               :@"BIND_OPCODE_DO_BIND_ULEB_TIMES_SKIPPING_ULEB"
                               :@""];
        
        uint32_t startNextBind = NSMaxRange(range);
        
        uint64_t count = [dataController read_uleb128:range lastReadHex:&lastReadHex];
        [node.details appendRow:[NSString stringWithFormat:@"%.8lX", range.location]
                               :lastReadHex
                               :@"uleb128"
                               :[NSString stringWithFormat:@"count (%qu)",count]];
        
        uint64_t skip = [dataController read_uleb128:range lastReadHex:&lastReadHex];
        [node.details appendRow:[NSString stringWithFormat:@"%.8lX", range.location]
                               :lastReadHex
                               :@"uleb128"
                               :[NSString stringWithFormat:@"skip (%qu)",skip]];
        
        [node.details setAttributes:MVUnderlineAttributeName,@"YES",nil];
        
        for (uint64_t index = 0; index < count; index++) 
        {
          [self bindAddress:address 
                       type:type 
                 symbolName:symbolName 
                      flags:symbolFlags 
                     addend:addend 
             libraryOrdinal:libOrdinal 
                       node:actionNode
                   nodeType:nodeType
                   location:doBindLocation
                 dyldHelper:helper
                    ptrSize:ptrSize];
          
          doBindLocation = startNextBind;
          
          address += ptrSize + skip;
        }
      } break;
        
      default:
        [NSException raise:@"Bind info" format:@"Unknown opcode (%u %u)", 
         ((uint32_t)-1 & opcode), ((uint32_t)-1 & immediate)];
    }
  }

  return node;
}
//-----------------------------------------------------------------------------

- (void)exportSymbol:(uint64_t)address 
          symbolName:(NSString *)symbolName
               flags:(uint64_t)flags 
                node:(MVNode *)node
            location:(uint32_t)location
{
  //uint64_t address = [self is64bit] == NO ? [self fileOffsetToRVA:offset] : [self fileOffsetToRVA64:offset];
  
  NSString * descStr = [NSString stringWithFormat:@"%@ 0x%qX",
                        [self is64bit] == NO ? [self findSectionContainsRVA:address] : [self findSectionContainsRVA64:address],
                        address];
  
  if ((flags & EXPORT_SYMBOL_FLAGS_KIND_MASK) == EXPORT_SYMBOL_FLAGS_KIND_THREAD_LOCAL)
  {
    descStr = [descStr stringByAppendingString:@" [thread-local]"];
  }

  if (flags & EXPORT_SYMBOL_FLAGS_WEAK_DEFINITION)
  {
    descStr = [descStr stringByAppendingString:@" [weak-def]"];
  }

  if (flags & EXPORT_SYMBOL_FLAGS_REEXPORT)
  {
    descStr = [descStr stringByAppendingString:@" [reexport]"];
  }

  if (flags & EXPORT_SYMBOL_FLAGS_STUB_AND_RESOLVER)
  {
    descStr = [descStr stringByAppendingString:@" [stub & resolver]"];
  }
  
  [node.details insertRowWithOffset:location
                                   :[NSString stringWithFormat:@"%.8X", location]
                                   :@""
                                   :descStr
                                   :symbolName];
  
  [node.details setAttributes:MVMetaDataAttributeName,symbolName,nil];
}
//-----------------------------------------------------------------------------

- (void)printSymbols:(NSString *)prefix                    
            location:(uint32_t)location
           skipBytes:(uint32_t)skip
                node:(MVNode *)node
          actionNode:(MVNode *)actionNode
         baseAddress:(uint64_t)baseAddress
      exportLocation:(uint32_t &)exportLocation
{
  NSRange range = NSMakeRange(location + skip,0);
  NSString * lastReadHex;

  uint8_t terminalSize = [dataController read_uint8:range lastReadHex:&lastReadHex];
  [node.details insertRowWithOffset:range.location
                                   :[NSString stringWithFormat:@"%.8lX", range.location]
                                   :lastReadHex
                                   :@"Terminal Size"
                                   :[NSString stringWithFormat:@"%u",((uint32_t)-1 & terminalSize)]];
  
  if (terminalSize != 0) 
  {
    uint32_t terminalLocation = NSMaxRange(range);
    
    uint64_t flags = [dataController read_uleb128:range lastReadHex:&lastReadHex];
    [node.details insertRowWithOffset:range.location
                                     :[NSString stringWithFormat:@"%.8lX", range.location]
                                     :lastReadHex
                                     :@"Flags"
                                     :@""];

    if ((flags & EXPORT_SYMBOL_FLAGS_KIND_MASK) == EXPORT_SYMBOL_FLAGS_KIND_REGULAR)      [node.details insertRowWithOffset:range.location:@"":@"":@"00":@"EXPORT_SYMBOL_FLAGS_KIND_REGULAR"];
    if ((flags & EXPORT_SYMBOL_FLAGS_KIND_MASK) == EXPORT_SYMBOL_FLAGS_KIND_THREAD_LOCAL) [node.details insertRowWithOffset:range.location:@"":@"":@"01":@"EXPORT_SYMBOL_FLAGS_KIND_THREAD_LOCAL"];
    if (flags & EXPORT_SYMBOL_FLAGS_WEAK_DEFINITION)                                      [node.details insertRowWithOffset:range.location:@"":@"":@"04":@"EXPORT_SYMBOL_FLAGS_WEAK_DEFINITION"];
    if (flags & EXPORT_SYMBOL_FLAGS_REEXPORT)                                             [node.details insertRowWithOffset:range.location:@"":@"":@"08":@"EXPORT_SYMBOL_FLAGS_REEXPORT"];
    if (flags & EXPORT_SYMBOL_FLAGS_STUB_AND_RESOLVER)                                    [node.details insertRowWithOffset:range.location:@"":@"":@"10":@"EXPORT_SYMBOL_FLAGS_STUB_AND_RESOLVER"];
    
    uint64_t offset = [dataController read_uleb128:range lastReadHex:&lastReadHex];
    [node.details insertRowWithOffset:range.location
                                     :[NSString stringWithFormat:@"%.8lX", range.location]
                                     :lastReadHex
                                     :@"Symbol Offset"
                                     :[NSString stringWithFormat:@"0x%qX",offset]];
    
    //=================================================================
    [self exportSymbol:baseAddress + offset
            symbolName:prefix
                 flags:flags 
                  node:actionNode
              location:exportLocation];
    //=================================================================
    
    range = NSMakeRange(terminalLocation, terminalSize);
  }
  
  uint8_t childCount = [dataController read_uint8:range lastReadHex:&lastReadHex];
  [node.details insertRowWithOffset:range.location
                                   :[NSString stringWithFormat:@"%.8lX", range.location]
                                   :lastReadHex
                                   :@"Child Count"
                                   :[NSString stringWithFormat:@"%u",((uint32_t)-1 & childCount)]];
  
  if (childCount == 0)
  {
    // separate export nodes
    [node.details setAttributes:MVUnderlineAttributeName,@"YES",nil];
  }
  
  while (childCount-- > 0)
  {
    exportLocation = NSMaxRange(range);
    
    NSString * label = [dataController read_string:range lastReadHex:&lastReadHex];
    [node.details insertRowWithOffset:range.location
                                     :[NSString stringWithFormat:@"%.8lX", range.location]
                                     :lastReadHex
                                     :@"Node Label"
                                     :[NSString stringWithFormat:@"\"%@\"",label]];
     
    uint64_t skip = [dataController read_uleb128:range lastReadHex:&lastReadHex];
    [node.details insertRowWithOffset:range.location
                                     :[NSString stringWithFormat:@"%.8lX", range.location]
                                     :lastReadHex
                                     :@"Next Node"
                                     :[self is64bit] == NO 
                                        ? [NSString stringWithFormat:@"0x%X",[self fileOffsetToRVA:location + skip]]
                                        : [NSString stringWithFormat:@"0x%qX",[self fileOffsetToRVA64:location + skip]]];
    
    if (childCount == 0)
    {
      // separate export nodes
      [node.details setAttributes:MVUnderlineAttributeName,@"YES",nil];
    }
    
    [self printSymbols:[NSString stringWithFormat:@"%@%@", prefix, label]
              location:location
             skipBytes:skip
                  node:node 
            actionNode:actionNode
           baseAddress:baseAddress
        exportLocation:exportLocation];
  }
}
//-----------------------------------------------------------------------------

- (MVNode *)createExportNode:(MVNode *)parent
                     caption:(NSString *)caption
                    location:(uint32_t)location
                      length:(uint32_t)length
                 baseAddress:(uint64_t)baseAddress
{
  MVNode * dataNode = [self createDataNode:parent 
                                   caption:caption 
                                  location:location 
                                    length:length];
  
  MVNodeSaver nodeSaver;
  MVNode * node = [dataNode insertChildWithDetails:@"Opcodes" location:location length:length saver:nodeSaver];
  
  MVNodeSaver actionNodeSaver;
  MVNode * actionNode = [dataNode insertChildWithDetails:@"Actions" location:location length:length saver:actionNodeSaver];
  
  uint32_t exportLocation = location;
  
  // start to traverse with initial values
  [self printSymbols:@"" 
            location:location 
           skipBytes:0 
                node:node
          actionNode:actionNode
         baseAddress:baseAddress
      exportLocation:exportLocation];
  
  // line up the details of traversal
  [node sortDetails];
  [actionNode sortDetails];
  
  return node;
}
//-----------------------------------------------------------------------------

@end
