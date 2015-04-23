/*
 *  MachOLayout.mm
 *  MachOView
 *
 *  Created by psaghelyi on 15/06/2010.
 *
 */

#import "Common.h"
#import "MachOLayout.h"
#import "DataController.h"
#import "ReadWrite.h"
#import "LoadCommands.h"
#import "LinkEdit.h"
#import "DyldInfo.h"
#import "Exceptions.h"
#import "SectionContents.h"
#import "ObjC.h"
#import "CRTFootPrints.h"

using namespace std;

//============================================================================
@implementation MachOLayout

// ----------------------------------------------------------------------------
- (id)init
{
  NSAssert(NO, @"plain init is not allowed");
  return nil;
}

//-----------------------------------------------------------------------------
- (id)initWithDataController:(MVDataController *)dc rootNode:(MVNode *)node 
{
  if (self = [super initWithDataController:dc rootNode:node])
  {
    symbolNames = [[NSMutableDictionary alloc] init];
  }
  return self;
}

//-----------------------------------------------------------------------------
+ (MachOLayout *)layoutWithDataController:(MVDataController *)dc rootNode:(MVNode *)node
{
  return [[MachOLayout alloc] initWithDataController:dc rootNode:node];
}

//-----------------------------------------------------------------------------
- (BOOL)is64bit
{
  MATCH_STRUCT(mach_header,imageOffset);
  return ((mach_header->cputype & CPU_ARCH_ABI64) == CPU_ARCH_ABI64);
}

//-----------------------------------------------------------------------------
- (BOOL)isDylibStub
{
  MATCH_STRUCT(mach_header,imageOffset);
  return (mach_header->filetype == MH_DYLIB_STUB);
}

//-----------------------------------------------------------------------------
- (struct section const *)getSectionByIndex:(uint32_t)index
{
  static const struct section notfound = { "???", "?????", 0, 0, 0, 0, 0, 0, 0, 0, 0 };
  return (index < sections.size() ? sections.at(index) : &notfound);
}

//-----------------------------------------------------------------------------
- (struct section_64 const *)getSection64ByIndex:(uint32_t)index
{
  static const struct section_64 notfound = { "???", "?????", 0, 0, 0, 0, 0, 0, 0, 0, 0 };
  return (index < sections_64.size() ? sections_64.at(index) : &notfound);
}

//-----------------------------------------------------------------------------
- (struct nlist const *)getSymbolByIndex:(uint32_t)index
{
  static const struct nlist notfound = { 0, 0, 0, 0, 0 }; 
  return (index < symbols.size() ? symbols.at(index) : &notfound);
}

//-----------------------------------------------------------------------------
- (struct nlist_64 const *)getSymbol64ByIndex:(uint32_t)index
{
  static const struct nlist_64 notfound = { 0, 0, 0, 0, 0 }; 
  return (index < symbols_64.size() ? symbols_64.at(index) : &notfound);
}

//-----------------------------------------------------------------------------
- (struct dylib const *)getDylibByIndex:(uint32_t)index
{
  static const struct dylib notfound = { 0, 0, 0, 0 }; 
  return (index < dylibs.size() ? dylibs.at(index) : &notfound);
}

//-----------------------------------------------------------------------------
- (NSString *)findSymbolAtRVA:(uint32_t)rva
{
  NSParameterAssert([self is64bit] == NO);
  NSString * symbolName = [symbolNames objectForKey:[NSNumber numberWithUnsignedLong:rva]];
  return (symbolName != nil ? symbolName : [NSString stringWithFormat:@"0x%X",rva]);
}

//-----------------------------------------------------------------------------
- (NSString *)findSymbolAtRVA64:(uint64_t)rva64
{
  NSParameterAssert([self is64bit] == YES);
  // extend external symbols represented in 32bit to 64bit
  if ((int32_t)rva64 < 0)
  {
    rva64 |= 0xffffffff00000000LL;
  }
  NSString * symbolName = [symbolNames objectForKey:[NSNumber numberWithUnsignedLongLong:rva64]];
  return (symbolName != nil ? symbolName : [NSString stringWithFormat:@"0x%qX",rva64]);
}

//-----------------------------------------------------------------------------
-(struct section const *)findSectionByName:(char const *)sectname 
                                andSegment:(char const *)segname
{
    
  for (SectionVector::const_iterator sectIter = ++sections.begin(); 
       sectIter != sections.end(); ++sectIter)
  {
    struct section const * section = *sectIter;
    if ((segname == NULL || strncmp(section->segname,segname,16) == 0) && 
        strncmp(section->sectname,sectname,16) == 0)
    {
      return section;
    }
  }
  return NULL;
}

//-----------------------------------------------------------------------------
-(struct section_64 const *)findSection64ByName:(char const *)sectname 
                                     andSegment:(char const *)segname
{
  
  for (Section64Vector::const_iterator sectIter = ++sections_64.begin(); 
       sectIter != sections_64.end(); ++sectIter)
  {
    struct section_64 const * section_64 = *sectIter;
    if ((segname == NULL || strncmp(section_64->segname,segname,16) == 0) &&
        strncmp(section_64->sectname,sectname,16) == 0)
    {
      return section_64;
    }
  }
  return NULL;
}

//-----------------------------------------------------------------------------
- (uint32_t)fileOffsetToRVA: (uint32_t)offset
{
  NSParameterAssert([self is64bit] == NO);
  
  SegmentInfoMap::const_iterator segIter = segmentInfo.upper_bound(offset);
  if (segIter == segmentInfo.begin())
  {
    [NSException raise:@"fileOffsetToRVA"
                format:@"no segment found at offset 0x%X", offset];
  }
  --segIter;
  uint32_t segOffset = segIter->first;
  uint32_t segAddr = segIter->second.first;
  return offset - segOffset + segAddr;
}

//-----------------------------------------------------------------------------
- (uint64_t)fileOffsetToRVA64: (uint32_t)offset
{
  NSParameterAssert([self is64bit] == YES);
  
  SegmentInfoMap::const_iterator segIter = segmentInfo.upper_bound(offset);
  if (segIter == segmentInfo.begin())
  {
    [NSException raise:@"fileOffsetToRVA64"
                format:@"no segment found at offset 0x%X", offset];
  }
  --segIter;
  uint32_t segOffset = segIter->first;
  uint64_t segAddr = segIter->second.first;
  return offset - segOffset + segAddr;
}

// ----------------------------------------------------------------------------
- (uint32_t)RVAToFileOffset: (uint32_t)rva
{
  NSParameterAssert([self is64bit] == NO);
  
  SectionInfoMap::const_iterator sectIter = sectionInfo.upper_bound(rva);
  if (sectIter == sectionInfo.begin())
  {
    [NSException raise:@"RVAToFileOffset"
                format:@"no section found at address 0x%X", rva];
  }
  --sectIter;
  uint32_t sectOffset = sectIter->second.first;
  uint32_t fileOffset = sectOffset + (rva - [self fileOffsetToRVA:sectOffset]);
  NSAssert1(fileOffset < [dataController.fileData length], @"rva is out of range (0x%X)", rva);
  return fileOffset;
}

// ----------------------------------------------------------------------------
- (uint32_t)RVA64ToFileOffset: (uint64_t)rva64
{
  NSParameterAssert([self is64bit] == YES);
  
  SectionInfoMap::const_iterator sectIter = sectionInfo.upper_bound(rva64);
  if (sectIter == sectionInfo.begin())
  {
    [NSException raise:@"RVA64ToFileOffset"
                format:@"no section found at address 0x%qX", rva64];
  }
  --sectIter;
  uint32_t sectOffset = sectIter->second.first;
  uint32_t fileOffset = sectOffset + (rva64 - [self fileOffsetToRVA64:sectOffset]);
  NSAssert1(fileOffset < [dataController.fileData length], @"rva is out of range (0x%qX)", rva64);
  return fileOffset;
}

// ----------------------------------------------------------------------------
- (void)addRelocAtFileOffset:(uint32_t)offset withLength:(uint32_t)length andValue:(uint64_t)value
{
  [dataController.realData replaceBytesInRange:NSMakeRange(offset,length) withBytes:&value];
}

// ----------------------------------------------------------------------------
static inline
uint32_t 
_hex2int(char const * a, uint32_t len)
{
  uint32_t val = 0;
  
  for(uint32_t i = 0; i < len; i++)
  {
    if(a[i] <= '9')
    {
      val += (a[i]-'0')*(1<<(4*(len-1-i)));
    }
    else
    {
      val += (a[i]-'7')*(1<<(4*(len-1-i)));
    }
  }
  
  return val;
}

// ----------------------------------------------------------------------------
// RAW string to RVA string converter for data source
- (NSString *)convertToRVA: (NSString *)offsetStr
{
  uint32_t fileOffset;
  
  /*
  BOOL scanResult = [[NSScanner scannerWithString:offsetStr] scanHexInt:&fileOffset];
  
  // return empty string if it is out of bounds
  if (scanResult == NO || segmentInfo.empty() || 
      fileOffset < segmentInfo.begin()->first || 
      fileOffset + 1 >= (--segmentInfo.end())->first + (--segmentInfo.end())->second.second)
  {
    return @"";
  }
  */
  // _hex2int is supposed to be must faster
  // note: on problems use the traditional scanner!
  
  fileOffset = _hex2int(CSTRING(offsetStr), [offsetStr length]);
  
  if (segmentInfo.empty() || 
      fileOffset < segmentInfo.begin()->first || 
      fileOffset + 1 >= (--segmentInfo.end())->first + (--segmentInfo.end())->second.second)
  {
    return @"";
  }
  
  return ([self is64bit] == NO 
          ? [NSString stringWithFormat:@"%.8X",[self fileOffsetToRVA:fileOffset]]
          : [NSString stringWithFormat:@"%.8qX",[self fileOffsetToRVA64:fileOffset]]);
}

// ----------------------------------------------------------------------------
- (NSDictionary *)userInfoForSection:(struct section const *)section
{
  if (section == NULL) return nil;
  typeof(self) __weak weakSelf = self;
  return [NSDictionary dictionaryWithObjectsAndKeys:
          weakSelf,MVLayoutUserInfoKey,
          NSSTRING(string(section->segname,16).c_str()), @"segname",
          NSSTRING(string(section->sectname,16).c_str()), @"sectname",
          [NSNumber numberWithUnsignedLong:section->addr], @"address",
          nil];
}

//-----------------------------------------------------------------------------
- (NSDictionary *)userInfoForSection64:(struct section_64 const *)section_64
{
  if (section_64 == NULL) return nil;
  typeof(self) __weak weakSelf = self;
  return [NSDictionary dictionaryWithObjectsAndKeys:
          weakSelf,MVLayoutUserInfoKey,
          NSSTRING(string(section_64->segname,16).c_str()), @"segname",
          NSSTRING(string(section_64->sectname,16).c_str()), @"sectname",
          [NSNumber numberWithUnsignedLongLong:section_64->addr], @"address",
          nil];
}

//-----------------------------------------------------------------------------
- (NSDictionary *)userInfoForRelocs
{
  typeof(self) __weak weakSelf = self;
  return [NSDictionary dictionaryWithObjectsAndKeys:
          weakSelf,MVLayoutUserInfoKey,
          @"Relocations", MVNodeUserInfoKey,
          nil];
}

//-----------------------------------------------------------------------------
- (NSDictionary *)sectionInfoForRVA:(uint32_t)rva
{
  NSParameterAssert([self is64bit] == NO);
  SectionInfoMap::iterator iter = sectionInfo.upper_bound(rva);
  if (iter == sectionInfo.begin())
  {
    NSLog(@"warning: no section info found for address 0x%.8X",rva);
    return nil;
  }
  return (--iter)->second.second;
}

//-----------------------------------------------------------------------------
- (NSDictionary *)sectionInfoForRVA64:(uint64_t)rva64
{
  NSParameterAssert([self is64bit] == YES);
  SectionInfoMap::iterator iter = sectionInfo.upper_bound(rva64);
  if (iter == sectionInfo.begin())
  {
    NSLog(@"warning: no section info found for address 0x%.16qX",rva64);
    return nil;
  }
  return (--iter)->second.second;
}
//-----------------------------------------------------------------------------
- (NSString *)findSectionContainsRVA:(uint32_t)rva
{
  NSDictionary * userInfo = [self sectionInfoForRVA:rva];
  return (userInfo ? [NSString stringWithFormat:@"%8s %-16s",
                      CSTRING([userInfo objectForKey:@"segname"]),
                      CSTRING([userInfo objectForKey:@"sectname"])] : @"NO SECTION               ");
}

//-----------------------------------------------------------------------------
- (NSString *)findSectionContainsRVA64:(uint64_t)rva64
{
  NSDictionary * userInfo = [self sectionInfoForRVA64:rva64];
  return (userInfo ? [NSString stringWithFormat:@"%8s %-16s",
                      CSTRING([userInfo objectForKey:@"segname"]),
                      CSTRING([userInfo objectForKey:@"sectname"])] : @"NO SECTION               ");
}

//------------------------------------------------------------------------------
- (MVNode *)sectionNodeContainsRVA:(uint32_t)rva
{
  NSDictionary * userInfo = [self sectionInfoForRVA:rva];
  return (userInfo ? [self findNodeByUserInfo:userInfo] : nil);
}

//------------------------------------------------------------------------------
- (MVNode *)sectionNodeContainsRVA64:(uint64_t)rva64
{
  NSDictionary * userInfo = [self sectionInfoForRVA64:rva64];
  return (userInfo ? [self findNodeByUserInfo:userInfo] : nil);
}

//-----------------------------------------------------------------------------
-(void) processLinkEdit
{
  // find related load commands
  struct symtab_command const * symtab_command = NULL;
  struct dysymtab_command const * dysymtab_command = NULL;
  struct twolevel_hints_command const * twolevel_hints_command = NULL;
  struct linkedit_data_command const * segment_split_info = NULL;
  struct linkedit_data_command const * code_signature = NULL;
  struct linkedit_data_command const * function_starts = NULL;
  struct linkedit_data_command const * data_in_code_entries = NULL;
  
  MATCH_STRUCT(mach_header,imageOffset);
  
  uint32_t base_addr;
  uint32_t seg1addr = (uint32_t)-1;
  uint32_t segs_read_write_addr = (uint32_t)-1;

  for (CommandVector::const_iterator cmdIter = commands.begin(); cmdIter != commands.end(); ++cmdIter)
  {
    struct load_command const * load_command = *cmdIter;
    switch (load_command->cmd)
    {
      case LC_SEGMENT:        
      {
        struct segment_command const * segment_command = (struct segment_command const *)load_command;
        
        if (segment_command->fileoff == 0 && segment_command->filesize != 0)
        {
					base_addr = segment_command->vmaddr;
        }

        if(segment_command->vmaddr < seg1addr)
        {
          seg1addr = segment_command->vmaddr;
        }
        
        // Pickup the address of the first read-write segment for MH_SPLIT_SEGS images.
        if((segment_command->initprot & VM_PROT_WRITE) == VM_PROT_WRITE &&
           segment_command->vmaddr < segs_read_write_addr)
        {
          segs_read_write_addr = segment_command->vmaddr;
        }
      } break;        
      case LC_SYMTAB: symtab_command = (struct symtab_command const *)load_command; break;
      case LC_DYSYMTAB: dysymtab_command = (struct dysymtab_command const *)load_command; break;
      case LC_TWOLEVEL_HINTS: twolevel_hints_command = (struct twolevel_hints_command const *)load_command; break;
      case LC_SEGMENT_SPLIT_INFO: segment_split_info = (struct linkedit_data_command const *)load_command; break;
      case LC_CODE_SIGNATURE: code_signature = (struct linkedit_data_command const *)load_command; break;
      case LC_FUNCTION_STARTS: function_starts = (struct linkedit_data_command const *)load_command; break;
      case LC_DATA_IN_CODE: data_in_code_entries = (struct linkedit_data_command const *)load_command; break;
      default: ; // not interested
    }
  }
  
  MVNode * symtabNode = nil;
  MVNode * dysymtabNode = nil;
  MVNode * twoLevelHintsNode = nil;
  MVNode * segmentSplitInfoNode = nil;
  MVNode * functionStartsNode = nil;
  MVNode * dataInCodeEntriesNode = nil;
  
  NSString * lastNodeCaption;
  
  if (symtab_command)
  {
    symtabNode = [self createDataNode:rootNode
                              caption:@"Symbol Table"
                             location:symtab_command->symoff + imageOffset
                               length:symtab_command->nsyms * sizeof(struct nlist)];
    
    [self createDataNode:rootNode 
                 caption:@"String Table"
                location:symtab_command->stroff + imageOffset
                  length:symtab_command->strsize];
  }
  
  if (dysymtab_command)
  {
    NSRange dysymtabRange = NSMakeRange(0,0);
    if (dysymtab_command->tocoff > 0)
    {
      NSRange range = NSMakeRange(dysymtab_command->tocoff + imageOffset, dysymtab_command->ntoc * sizeof(struct dylib_table_of_contents));
      dysymtabRange = NSMaxRange(dysymtabRange) > 0 ? NSUnionRange(dysymtabRange, range) : range;
    }
    if (dysymtab_command->modtaboff > 0)
    {
      NSRange range = NSMakeRange(dysymtab_command->modtaboff + imageOffset, dysymtab_command->nmodtab * sizeof(struct dylib_module));
      dysymtabRange = NSMaxRange(dysymtabRange) > 0 ? NSUnionRange(dysymtabRange, range) : range;
    }
    if (dysymtab_command->extrefsymoff > 0)
    {
      NSRange range = NSMakeRange(dysymtab_command->extrefsymoff + imageOffset, dysymtab_command->nextrefsyms * sizeof(struct dylib_reference));
      dysymtabRange = NSMaxRange(dysymtabRange) > 0 ? NSUnionRange(dysymtabRange, range) : range;
    }
    if (dysymtab_command->indirectsymoff > 0)
    {
      NSRange range = NSMakeRange(dysymtab_command->indirectsymoff + imageOffset, dysymtab_command->nindirectsyms * sizeof(uint32_t));
      dysymtabRange = NSMaxRange(dysymtabRange) > 0 ? NSUnionRange(dysymtabRange, range) : range;
    }
    if (dysymtab_command->extreloff > 0)
    {
      NSRange range = NSMakeRange(dysymtab_command->extreloff + imageOffset, dysymtab_command->nextrel * sizeof(struct relocation_info));
      dysymtabRange = NSMaxRange(dysymtabRange) > 0 ? NSUnionRange(dysymtabRange, range) : range;
    }
    if (dysymtab_command->locreloff > 0)
    {
      NSRange range = NSMakeRange(dysymtab_command->locreloff + imageOffset, dysymtab_command->nlocrel * sizeof(struct relocation_info));
      dysymtabRange = NSMaxRange(dysymtabRange) > 0 ? NSUnionRange(dysymtabRange, range) : range;
    }
    if (dysymtabRange.length > 0)
    {
      dysymtabNode = [self createDataNode:rootNode
                                  caption:@"Dynamic Symbol Table"
                                 location:dysymtabRange.location
                                   length:dysymtabRange.length];
    }
  }
  
  if (twolevel_hints_command)
  {
    twoLevelHintsNode = [self createDataNode:rootNode 
                                     caption:@"Two Level Hints Table"
                                    location:twolevel_hints_command->offset + imageOffset
                                      length:twolevel_hints_command->nhints * sizeof(struct twolevel_hint)];
  }

  if (segment_split_info)
  {
    segmentSplitInfoNode = [self createDataNode:rootNode 
                                        caption:@"Segment Split Info"
                                       location:segment_split_info->dataoff + imageOffset
                                         length:segment_split_info->datasize];
  }
  
  if (code_signature)
  {
    [self createDataNode:rootNode 
                 caption:@"Code Signature"
                location:code_signature->dataoff + imageOffset
                  length:code_signature->datasize];
  }
  
  if (function_starts)
  {
    functionStartsNode = [self createDataNode:rootNode 
                                      caption:@"Function Starts"
                                     location:function_starts->dataoff + imageOffset
                                       length:function_starts->datasize];
  }
  
  if (data_in_code_entries)
  {
    dataInCodeEntriesNode = [self createDataNode:rootNode
                                         caption:@"Data in Code Entries"
                                        location:data_in_code_entries->dataoff + imageOffset
                                          length:data_in_code_entries->datasize];
  }
  
  //============ Symbol Table ====================
  //==============================================
  if (symtabNode)
  {
    @try
    {
      [self createSymbolsNode:symtabNode
                      caption:(lastNodeCaption = @"Symbols")
                     location:symtabNode.dataRange.location
                       length:symtabNode.dataRange.length];
    }
    @catch(NSException * exception)
    {
      [self printException:exception caption:lastNodeCaption];
    }
  }
  
  
  //=========== Dynamic Symbol Table =============
  //==============================================
  if (dysymtabNode)
  {
    @try
    {
      //=============== Module Table =================
      //==============================================
      if (dysymtab_command->modtaboff * dysymtab_command->nmodtab > 0)
      {
        [self createModulesNode:dysymtabNode 
                        caption:(lastNodeCaption = @"Modules")
                       location:dysymtab_command->modtaboff + imageOffset
                         length:dysymtab_command->nmodtab * sizeof(struct dylib_module)];
      }

      //========== Table of Contents =================
      //==============================================
      if (dysymtab_command->tocoff * dysymtab_command->ntoc > 0)
      {
        [self createTOCNode:dysymtabNode 
                    caption:(lastNodeCaption = @"Table of Contents")
                   location:dysymtab_command->tocoff + imageOffset 
                     length:dysymtab_command->ntoc * sizeof(struct dylib_table_of_contents)];
      }

      //======= External Reference Table =============
      //==============================================
      if (dysymtab_command->extrefsymoff * dysymtab_command->nextrefsyms > 0)
      {
        [self createReferencesNode:dysymtabNode 
                           caption:(lastNodeCaption = @"External References")
                          location:dysymtab_command->extrefsymoff + imageOffset
                            length:dysymtab_command->nextrefsyms * sizeof(struct dylib_reference)];
      }

      //========== Indirect Symbol Table =============
      //==============================================
      if (dysymtab_command->indirectsymoff * dysymtab_command->nindirectsyms > 0)
      {
        [self createISymbolsNode:dysymtabNode
                         caption:(lastNodeCaption = @"Indirect Symbols")
                        location:dysymtab_command->indirectsymoff + imageOffset
                          length:dysymtab_command->nindirectsyms * sizeof(uint32_t)];
      }

      //========== External Reloc Table ==============
      //==============================================
      if (dysymtab_command->extreloff * dysymtab_command->nextrel > 0)
      {
        [self createRelocNode:dysymtabNode 
                      caption:(lastNodeCaption = @"External Relocations")
                     location:dysymtab_command->extreloff + imageOffset
                       length:dysymtab_command->nextrel * sizeof(struct relocation_info)
                  baseAddress:(mach_header->flags & MH_SPLIT_SEGS) == MH_SPLIT_SEGS ? segs_read_write_addr : seg1addr];
      }

      //=========== Local Reloc Table ================
      //==============================================
      if (dysymtab_command->locreloff * dysymtab_command->nlocrel > 0)
      {
        [self createRelocNode:dysymtabNode 
                      caption:(lastNodeCaption = @"Local Relocations")
                     location:dysymtab_command->locreloff + imageOffset
                       length:dysymtab_command->nlocrel * sizeof(struct relocation_info)
                  baseAddress:(mach_header->flags & MH_SPLIT_SEGS) == MH_SPLIT_SEGS ? segs_read_write_addr : seg1addr];
      }
    }
    @catch(NSException * exception)
    {
      [self printException:exception caption:lastNodeCaption];
    }
  }
  
  if (twoLevelHintsNode && twoLevelHintsNode.dataRange.length > 0)
  {
    @try
    {
      [self createTwoLevelHintsNode:twoLevelHintsNode 
                            caption:(lastNodeCaption = @"Hints") 
                           location:twoLevelHintsNode.dataRange.location
                             length:twoLevelHintsNode.dataRange.length
                              index:dysymtab_command->iundefsym];
    }
    @catch(NSException * exception)
    {
      [self printException:exception caption:lastNodeCaption];
    }
  }

  if (segmentSplitInfoNode && segmentSplitInfoNode.dataRange.length > 0)
  {
    @try
    {
      [self createSplitSegmentNode:segmentSplitInfoNode 
                           caption:(lastNodeCaption = @"Shared Region Info")
                          location:segmentSplitInfoNode.dataRange.location
                            length:segmentSplitInfoNode.dataRange.length
                       baseAddress:base_addr];
    }
    @catch(NSException * exception)
    {
      [self printException:exception caption:lastNodeCaption];
    }
  }
  
  if (functionStartsNode && functionStartsNode.dataRange.length > 0)
  {
    @try
    {
      [self createFunctionStartsNode:functionStartsNode 
                             caption:(lastNodeCaption = @"Functions")  
                            location:functionStartsNode.dataRange.location 
                              length:functionStartsNode.dataRange.length
                         baseAddress:base_addr];
    }
    @catch(NSException * exception)
    {
      [self printException:exception caption:lastNodeCaption];
    }
  }
  
  if (dataInCodeEntriesNode && dataInCodeEntriesNode.dataRange.length > 0)
  {
    @try
    {
      [self createDataInCodeEntriesNode:dataInCodeEntriesNode
                                caption:(lastNodeCaption = @"Dices")
                               location:dataInCodeEntriesNode.dataRange.location
                                 length:dataInCodeEntriesNode.dataRange.length];
    }
    @catch(NSException * exception)
    {
      [self printException:exception caption:lastNodeCaption];
    }
  }
}

//-----------------------------------------------------------------------------
-(void) processLinkEdit64
{
  // find related load commands
  struct symtab_command const * symtab_command = NULL;
  struct dysymtab_command const * dysymtab_command = NULL;
  struct twolevel_hints_command const * twolevel_hints_command = NULL;
  struct linkedit_data_command const * segment_split_info = NULL;
  struct linkedit_data_command const * code_signature = NULL;
  struct linkedit_data_command const * function_starts = NULL;
  struct linkedit_data_command const * data_in_code_entries = NULL;
  
  MATCH_STRUCT(mach_header_64,imageOffset);
  
  uint64_t base_addr;
  uint64_t seg1addr = (uint64_t)-1LL;
  uint64_t segs_read_write_addr = (uint64_t)-1LL;
  
  for (CommandVector::const_iterator cmdIter = commands.begin(); cmdIter != commands.end(); ++cmdIter)
  {
    struct load_command const * load_command = *cmdIter;
    switch (load_command->cmd)
    {
      case LC_SEGMENT_64:     
      {
        struct segment_command_64 const * segment_command_64 = (struct segment_command_64 const *)load_command;
        
        if (segment_command_64->fileoff == 0 && segment_command_64->filesize != 0)
        {
					base_addr = segment_command_64->vmaddr;
        }
        
        if(segment_command_64->vmaddr < seg1addr)
        {
          seg1addr = segment_command_64->vmaddr;
        }
        
        // Pickup the address of the first read-write segment for MH_SPLIT_SEGS images.
        if((segment_command_64->initprot & VM_PROT_WRITE) == VM_PROT_WRITE &&
           segment_command_64->vmaddr < segs_read_write_addr)
        {
          segs_read_write_addr = segment_command_64->vmaddr;
        }
      } break;
      case LC_SYMTAB: symtab_command = (struct symtab_command const *)load_command; break;
      case LC_DYSYMTAB: dysymtab_command = (struct dysymtab_command const *)load_command; break;
      case LC_TWOLEVEL_HINTS: twolevel_hints_command = (struct twolevel_hints_command const *)load_command; break;
      case LC_SEGMENT_SPLIT_INFO: segment_split_info = (struct linkedit_data_command const *)load_command; break;
      case LC_CODE_SIGNATURE: code_signature = (struct linkedit_data_command const *)load_command; break;
      case LC_FUNCTION_STARTS: function_starts = (struct linkedit_data_command const *)load_command; break;
      case LC_DATA_IN_CODE: data_in_code_entries = (struct linkedit_data_command const *)load_command; break;
      default: ; // not interested
    }
  }

  MVNode * symtabNode = nil;
  MVNode * dysymtabNode = nil;
  MVNode * twoLevelHintsNode = nil;
  MVNode * segmentSplitInfoNode = nil;
  MVNode * functionStartsNode = nil;
  MVNode * dataInCodeEntriesNode = nil;

  NSString * lastNodeCaption;
  
  if (symtab_command)
  {
    symtabNode = [self createDataNode:rootNode
                              caption:@"Symbol Table"
                             location:symtab_command->symoff + imageOffset
                               length:symtab_command->nsyms * sizeof(struct nlist_64)];
    
    [self createDataNode:rootNode 
                 caption:@"String Table"
                location:symtab_command->stroff + imageOffset
                  length:symtab_command->strsize];
  }
  
  if (dysymtab_command)
  {
    NSRange dysymtabRange = NSMakeRange(0,0);
    if (dysymtab_command->tocoff > 0)
    {
      NSRange range = NSMakeRange(dysymtab_command->tocoff + imageOffset, dysymtab_command->ntoc * sizeof(struct dylib_table_of_contents));
      dysymtabRange = NSMaxRange(dysymtabRange) > 0 ? NSUnionRange(dysymtabRange, range) : range;
    }
    if (dysymtab_command->modtaboff > 0)
    {
      NSRange range = NSMakeRange(dysymtab_command->modtaboff + imageOffset, dysymtab_command->nmodtab * sizeof(struct dylib_module_64));
      dysymtabRange = NSMaxRange(dysymtabRange) > 0 ? NSUnionRange(dysymtabRange, range) : range;
    }
    if (dysymtab_command->extrefsymoff > 0)
    {
      NSRange range = NSMakeRange(dysymtab_command->extrefsymoff + imageOffset, dysymtab_command->nextrefsyms * sizeof(struct dylib_reference));
      dysymtabRange = NSMaxRange(dysymtabRange) > 0 ? NSUnionRange(dysymtabRange, range) : range;
    }
    if (dysymtab_command->indirectsymoff > 0)
    {
      NSRange range = NSMakeRange(dysymtab_command->indirectsymoff + imageOffset, dysymtab_command->nindirectsyms * sizeof(uint32_t));
      dysymtabRange = NSMaxRange(dysymtabRange) > 0 ? NSUnionRange(dysymtabRange, range) : range;
    }
    if (dysymtab_command->extreloff > 0)
    {
      NSRange range = NSMakeRange(dysymtab_command->extreloff + imageOffset, dysymtab_command->nextrel * sizeof(struct relocation_info));
      dysymtabRange = NSMaxRange(dysymtabRange) > 0 ? NSUnionRange(dysymtabRange, range) : range;
    }
    if (dysymtab_command->locreloff > 0)
    {
      NSRange range = NSMakeRange(dysymtab_command->locreloff + imageOffset, dysymtab_command->nlocrel * sizeof(struct relocation_info));
      dysymtabRange = NSMaxRange(dysymtabRange) > 0 ? NSUnionRange(dysymtabRange, range) : range;
    }
    if (dysymtabRange.length > 0)
    {
      dysymtabNode = [self createDataNode:rootNode
                                  caption:@"Dynamic Symbol Table"
                                 location:dysymtabRange.location
                                   length:dysymtabRange.length];
    }
  }
  
  if (twolevel_hints_command)
  {
    twoLevelHintsNode = [self createDataNode:rootNode 
                                     caption:@"Two Level Hints Table"
                                    location:twolevel_hints_command->offset + imageOffset
                                      length:twolevel_hints_command->nhints * sizeof(struct twolevel_hint)];
  }
  
  if (segment_split_info)
  {
    segmentSplitInfoNode = [self createDataNode:rootNode 
                                        caption:@"Segment Split Info"
                                       location:segment_split_info->dataoff + imageOffset
                                         length:segment_split_info->datasize];
  }

  if (code_signature)
  {
    [self createDataNode:rootNode 
                 caption:@"Code Signature"
                location:code_signature->dataoff + imageOffset
                  length:code_signature->datasize];
  }

  if (function_starts)
  {
    functionStartsNode = [self createDataNode:rootNode 
                                      caption:@"Function Starts"
                                     location:function_starts->dataoff + imageOffset
                                       length:function_starts->datasize];
  }

  if (data_in_code_entries)
  {
    dataInCodeEntriesNode = [self createDataNode:rootNode
                                         caption:@"Data in Code Entries"
                                        location:data_in_code_entries->dataoff + imageOffset
                                          length:data_in_code_entries->datasize];
  }
  
  //============ Symbol Table ====================
  //==============================================
  if (symtabNode)
  {
    @try
    {
      [self createSymbols64Node:symtabNode
                        caption:(lastNodeCaption = @"Symbols")
                       location:symtabNode.dataRange.location
                         length:symtabNode.dataRange.length];
    }
    @catch(NSException * exception)
    {
      [self printException:exception caption:lastNodeCaption];
    }
  }
  

  //=========== Dynamic Symbol Table =============
  //==============================================
  if (dysymtabNode)
  {
    @try
    {
      //=============== Module Table =================
      //==============================================
      if (dysymtab_command->modtaboff * dysymtab_command->nmodtab > 0)
      {
        [self createModules64Node:dysymtabNode 
                          caption:(lastNodeCaption = @"Modules64")
                         location:dysymtab_command->modtaboff + imageOffset
                           length:dysymtab_command->nmodtab * sizeof(struct dylib_module_64)];
      }  

      //========== Table of Contents =================
      //==============================================
      if (dysymtab_command->tocoff * dysymtab_command->ntoc > 0)
      {
        [self createTOC64Node:dysymtabNode 
                      caption:(lastNodeCaption = @"Table of Contents")
                     location:dysymtab_command->tocoff + imageOffset 
                       length:dysymtab_command->ntoc * sizeof(struct dylib_table_of_contents)];
      }

      //======= External Reference Table =============
      //==============================================
      if (dysymtab_command->extrefsymoff * dysymtab_command->nextrefsyms > 0)
      {
        [self createReferencesNode:dysymtabNode 
                           caption:(lastNodeCaption = @"External References")
                          location:dysymtab_command->extrefsymoff + imageOffset
                            length:dysymtab_command->nextrefsyms * sizeof(struct dylib_reference)];
      }

      //========== Indirect Symbol Table =============
      //==============================================
      if (dysymtab_command->indirectsymoff * dysymtab_command->nindirectsyms > 0)
      {
        [self createISymbols64Node:dysymtabNode
                           caption:(lastNodeCaption = @"Indirect Symbols")
                          location:dysymtab_command->indirectsymoff + imageOffset
                            length:dysymtab_command->nindirectsyms * sizeof(uint32_t)];
      }

      //========== External Reloc Table ==============
      //==============================================
      if (dysymtab_command->extreloff * dysymtab_command->nextrel > 0)
      {
        [self createReloc64Node:dysymtabNode 
                        caption:(lastNodeCaption = @"External Relocations")
                       location:dysymtab_command->extreloff + imageOffset
                         length:dysymtab_command->nextrel * sizeof(struct relocation_info)
                    baseAddress:(mach_header_64->flags & MH_SPLIT_SEGS) == MH_SPLIT_SEGS ? segs_read_write_addr : seg1addr];
      }

      //=========== Local Reloc Table ================
      //==============================================
      if (dysymtab_command->locreloff * dysymtab_command->nlocrel > 0)
      {
        [self createReloc64Node:dysymtabNode 
                        caption:(lastNodeCaption = @"Local Reloc Table")
                       location:dysymtab_command->locreloff + imageOffset
                         length:dysymtab_command->nlocrel * sizeof(struct relocation_info)
                    baseAddress:(mach_header_64->flags & MH_SPLIT_SEGS) == MH_SPLIT_SEGS ? segs_read_write_addr : seg1addr];
      }
    }
    @catch(NSException * exception)
    {
      [self printException:exception caption:lastNodeCaption];
    }
  }
  
  if (twoLevelHintsNode && twoLevelHintsNode.dataRange.length > 0)
  {
    @try
    {
      [self createTwoLevelHintsNode:twoLevelHintsNode 
                            caption:(lastNodeCaption = @"Hints") 
                           location:twoLevelHintsNode.dataRange.location
                             length:twoLevelHintsNode.dataRange.length
                              index:dysymtab_command->iundefsym];
    }
    @catch(NSException * exception)
    {
      [self printException:exception caption:lastNodeCaption];
    }
  }
  
  if (segmentSplitInfoNode && segmentSplitInfoNode.dataRange.length > 0)
  {
    @try
    {
      [self createSplitSegmentNode:segmentSplitInfoNode 
                           caption:(lastNodeCaption = @"Shared Region Info") 
                          location:segmentSplitInfoNode.dataRange.location
                            length:segmentSplitInfoNode.dataRange.length
                       baseAddress:base_addr];
    }
    @catch(NSException * exception)
    {
      [self printException:exception caption:lastNodeCaption];
    }
  }  
  
  if (functionStartsNode && functionStartsNode.dataRange.length > 0)
  {
    @try
    {
      [self createFunctionStartsNode:functionStartsNode 
                             caption:(lastNodeCaption = @"Functions")  
                            location:functionStartsNode.dataRange.location 
                              length:functionStartsNode.dataRange.length
                         baseAddress:base_addr];
    }
    @catch(NSException * exception)
    {
      [self printException:exception caption:lastNodeCaption];
    }
  }
  
  if (dataInCodeEntriesNode && dataInCodeEntriesNode.dataRange.length > 0)
  {
    @try
    {
      [self createDataInCodeEntriesNode:dataInCodeEntriesNode
                                caption:(lastNodeCaption = @"Dices")
                               location:dataInCodeEntriesNode.dataRange.location
                                 length:dataInCodeEntriesNode.dataRange.length];
    }
    @catch(NSException * exception)
    {
      [self printException:exception caption:lastNodeCaption];
    }
  }
}

//-----------------------------------------------------------------------------
-(void)processDyldInfo
{
  uint64_t base_addr = 0;
  
  // find related load commands
  struct dyld_info_command const * dyld_info_command = NULL;
  
  for (CommandVector::const_iterator cmdIter = commands.begin(); cmdIter != commands.end(); ++cmdIter)
  {
    struct load_command const * load_command = *cmdIter;
    switch (load_command->cmd)
    {
      case LC_SEGMENT:     
      {
        struct segment_command const * segment_command = (struct segment_command const *)load_command;
        if (segment_command->fileoff == 0 && segment_command->filesize != 0)
        {
					base_addr = segment_command->vmaddr;
        }
      } break;

      case LC_SEGMENT_64:     
      {
        struct segment_command_64 const * segment_command_64 = (struct segment_command_64 const *)load_command;
        if (segment_command_64->fileoff == 0 && segment_command_64->filesize != 0)
        {
					base_addr = segment_command_64->vmaddr;
        }
      } break;
      case LC_DYLD_INFO:
      case LC_DYLD_INFO_ONLY: dyld_info_command = (struct dyld_info_command const *)load_command; break;
      default: ; // not interested
    }
  }
  
  if (dyld_info_command == NULL)
  {
    return;
  }
  
  NSRange dyldInfoRange = NSMakeRange(0,0);
  if (dyld_info_command->rebase_off > 0)
  {
    NSRange range = NSMakeRange(dyld_info_command->rebase_off + imageOffset, dyld_info_command->rebase_size);
    dyldInfoRange = NSMaxRange(dyldInfoRange) > 0 ? NSUnionRange(dyldInfoRange, range) : range;
  }
  if (dyld_info_command->bind_off > 0)
  {
    NSRange range = NSMakeRange(dyld_info_command->bind_off + imageOffset, dyld_info_command->bind_size);
    dyldInfoRange = NSMaxRange(dyldInfoRange) > 0 ? NSUnionRange(dyldInfoRange, range) : range;
  }
  if (dyld_info_command->weak_bind_off > 0)
  {
    NSRange range = NSMakeRange(dyld_info_command->weak_bind_off + imageOffset, dyld_info_command->weak_bind_size);
    dyldInfoRange = NSMaxRange(dyldInfoRange) > 0 ? NSUnionRange(dyldInfoRange, range) : range;
  }
  if (dyld_info_command->lazy_bind_off > 0)
  {
    NSRange range = NSMakeRange(dyld_info_command->lazy_bind_off + imageOffset, dyld_info_command->lazy_bind_size);
    dyldInfoRange = NSMaxRange(dyldInfoRange) > 0 ? NSUnionRange(dyldInfoRange, range) : range;
  }
  if (dyld_info_command->export_off > 0)
  {
    NSRange range = NSMakeRange(dyld_info_command->export_off + imageOffset, dyld_info_command->export_size);
    dyldInfoRange = NSMaxRange(dyldInfoRange) > 0 ? NSUnionRange(dyldInfoRange, range) : range;
  }
  MVNode * dyldInfoNode = [self createDataNode:rootNode
                                       caption:@"Dynamic Loader Info"
                                      location:dyldInfoRange.location
                                        length:dyldInfoRange.length];
  
  DyldHelper * dyldHelper = [DyldHelper dyldHelperWithSymbols:symbolNames is64Bit:[self is64bit]];
  
  NSString * lastNodeCaption;
  @try 
  {
    if (dyld_info_command->rebase_off * dyld_info_command->rebase_size > 0)
    {
      [self createRebaseNode:dyldInfoNode
                     caption:(lastNodeCaption = @"Rebase Info")
                    location:dyld_info_command->rebase_off + imageOffset
                      length:dyld_info_command->rebase_size
                 baseAddress:base_addr];
    }

    if (dyld_info_command->bind_off * dyld_info_command->bind_size > 0)
    {
      [self createBindingNode:dyldInfoNode
                      caption:(lastNodeCaption = @"Binding Info")
                     location:dyld_info_command->bind_off + imageOffset
                       length:dyld_info_command->bind_size
                  baseAddress:base_addr
                     nodeType:NodeTypeBind
                   dyldHelper:dyldHelper];
    }

    if (dyld_info_command->weak_bind_off * dyld_info_command->weak_bind_size > 0)
    {
      [self createBindingNode:dyldInfoNode
                      caption:(lastNodeCaption = @"Weak Binding Info")
                     location:dyld_info_command->weak_bind_off + imageOffset
                       length:dyld_info_command->weak_bind_size
                  baseAddress:base_addr
                     nodeType:NodeTypeWeakBind
                   dyldHelper:dyldHelper];
    }

    if (dyld_info_command->lazy_bind_off * dyld_info_command->lazy_bind_size > 0)
    {
      [self createBindingNode:dyldInfoNode
                      caption:(lastNodeCaption = @"Lazy Binding Info")
                     location:dyld_info_command->lazy_bind_off + imageOffset
                       length:dyld_info_command->lazy_bind_size
                  baseAddress:base_addr
                     nodeType:NodeTypeLazyBind
                   dyldHelper:dyldHelper];
    }
    
    if (dyld_info_command->export_off * dyld_info_command->export_size > 0)
    {
      [self createExportNode:dyldInfoNode
                     caption:(lastNodeCaption = @"Export Info")
                    location:dyld_info_command->export_off + imageOffset
                      length:dyld_info_command->export_size
                 baseAddress:base_addr];
    }
  }
  @catch(NSException * exception)
  {
    [self printException:exception caption:lastNodeCaption];
  }
  
}

//-----------------------------------------------------------------------------
template <typename SectionT>
struct CompareSectionByName
{
  CompareSectionByName(char const * segname, char const * sectname) 
    : segname(segname)
    , sectname(sectname) 
  {
  }

  CompareSectionByName(char const * sectname) 
    : segname(NULL)
    , sectname(sectname) 
  {
  }
  
  bool operator() (SectionT const * section)
  {
    return ((segname == NULL || strncmp(segname,section->segname,16) == 0) && 
                                strncmp(sectname,section->sectname,16) == 0);
  }
  
  char const * segname;
  char const * sectname;
};

//-----------------------------------------------------------------------------
-(void)processSections
{
  NSString * lastNodeCaption;
  
  //================ sections with literal content ============================
  for (SectionVector::const_iterator sectIter = ++sections.begin(); sectIter != sections.end(); ++sectIter)
  {
    struct section const * section = *sectIter;
    MVNode * sectionNode = [self findNodeByUserInfo:[self userInfoForSection:section]];
    if (sectionNode == nil)
    {
      continue;
    }
    
    @try
    {
      switch (section->flags & SECTION_TYPE)
      {
        case S_CSTRING_LITERALS: 
          [self createCStringsNode:sectionNode 
                           caption:(lastNodeCaption = @"C String Literals")
                          location:section->offset + imageOffset
                            length:section->size]; break;
      
        case S_4BYTE_LITERALS:
          [self createLiteralsNode:sectionNode 
                           caption:(lastNodeCaption = @"Floating Point Literals")
                          location:section->offset + imageOffset
                            length:section->size
                            stride:4]; break;
          
        case S_8BYTE_LITERALS:
          [self createLiteralsNode:sectionNode 
                           caption:(lastNodeCaption = @"Floating Point Literals")
                          location:section->offset + imageOffset
                            length:section->size
                            stride:8]; break;

        case S_16BYTE_LITERALS:
          [self createLiteralsNode:sectionNode 
                           caption:(lastNodeCaption = @"Floating Point Literals")
                          location:section->offset + imageOffset
                            length:section->size
                            stride:16]; break;
      }
    }
    @catch(NSException * exception)
    {
      [self printException:exception caption:lastNodeCaption];
    }
  }

  //================ sections with pointer content ============================
  for (SectionVector::const_iterator sectIter = ++sections.begin(); sectIter != sections.end(); ++sectIter)
  {
    struct section const * section = *sectIter;
    MVNode * sectionNode = [self findNodeByUserInfo:[self userInfoForSection:section]];
    if (sectionNode == nil)
    {
      continue;
    }
    
    @try 
    {
      switch (section->flags & SECTION_TYPE)
      {
        case S_LITERAL_POINTERS:
          [self createPointersNode:sectionNode 
                           caption:(lastNodeCaption = @"Literal Pointers")
                          location:section->offset + imageOffset
                            length:section->size]; break;

        case S_MOD_INIT_FUNC_POINTERS:
          [self createPointersNode:sectionNode 
                           caption:(lastNodeCaption = @"Module Init Func Pointers") 
                          location:section->offset + imageOffset
                            length:section->size]; break;

        case S_MOD_TERM_FUNC_POINTERS:
          [self createPointersNode:sectionNode 
                           caption:(lastNodeCaption = @"Module Term Func Pointers") 
                          location:section->offset + imageOffset
                            length:section->size]; break;

        case S_LAZY_SYMBOL_POINTERS:
          [self createIndPointersNode:sectionNode 
                              caption:(lastNodeCaption = @"Lazy Symbol Pointers")
                             location:section->offset + imageOffset
                               length:section->size]; break;

        case S_NON_LAZY_SYMBOL_POINTERS:
          [self createIndPointersNode:sectionNode 
                              caption:(lastNodeCaption = @"Non-Lazy Symbol Pointers")
                             location:section->offset + imageOffset
                               length:section->size]; break;

        case S_LAZY_DYLIB_SYMBOL_POINTERS:
          [self createIndPointersNode:sectionNode 
                              caption:(lastNodeCaption = @"Lazy Dylib Symbol Pointers")
                             location:section->offset + imageOffset
                               length:section->size]; break;

        case S_SYMBOL_STUBS:
          [self createIndStubsNode:sectionNode 
                           caption:(lastNodeCaption = @"Symbol Stubs")
                          location:section->offset + imageOffset
                            length:section->size
                            stride:section->reserved2]; break;
       
        default:;
      }
    }
    @catch(NSException * exception)
    {
      [self printException:exception caption:lastNodeCaption];
    }
  }
  
}

//-----------------------------------------------------------------------------
-(void)processSections64
{
  NSString * lastNodeCaption;

  //================ sections with literal content ============================
  for (Section64Vector::const_iterator sectIter = ++sections_64.begin(); sectIter != sections_64.end(); ++sectIter)
  {
    struct section_64 const * section_64 = *sectIter;
    MVNode * sectionNode = [self findNodeByUserInfo:[self userInfoForSection64:section_64]];
    if (sectionNode == nil)
    {
      continue;
    }
    
    @try
    {
      switch (section_64->flags & SECTION_TYPE)
      {
        case S_CSTRING_LITERALS: 
          [self createCStringsNode:sectionNode 
                           caption:(lastNodeCaption = @"C String Literals")
                          location:section_64->offset + imageOffset
                            length:section_64->size]; break;
          
        case S_4BYTE_LITERALS:
          [self createLiteralsNode:sectionNode 
                           caption:(lastNodeCaption = @"Floating Point Literals")
                          location:section_64->offset + imageOffset
                            length:section_64->size
                            stride:4]; break;
          
        case S_8BYTE_LITERALS:
          [self createLiteralsNode:sectionNode 
                           caption:(lastNodeCaption = @"Floating Point Literals")
                          location:section_64->offset + imageOffset
                            length:section_64->size
                            stride:8]; break;
          
        case S_16BYTE_LITERALS:
          [self createLiteralsNode:sectionNode 
                           caption:(lastNodeCaption = @"Floating Point Literals")
                          location:section_64->offset + imageOffset
                            length:section_64->size
                            stride:16]; break;
      }
    }
    @catch(NSException * exception)
    {
      [self printException:exception caption:lastNodeCaption];
    }
  }
    
  //================ sections with pointer content ============================
  for (Section64Vector::const_iterator sectIter = ++sections_64.begin(); sectIter != sections_64.end(); ++sectIter)
  {
    struct section_64 const * section_64 = *sectIter;
    MVNode * sectionNode = [self findNodeByUserInfo:[self userInfoForSection64:section_64]];
    if (sectionNode == nil)
    {
      continue;
    }
    
    @try 
    {
      switch (section_64->flags & SECTION_TYPE)
      {
        case S_LITERAL_POINTERS:
          [self createPointers64Node:sectionNode 
                             caption:(lastNodeCaption = @"Literal Pointers")
                            location:section_64->offset + imageOffset
                              length:section_64->size]; break;
          
        case S_MOD_INIT_FUNC_POINTERS:
          [self createPointers64Node:sectionNode 
                             caption:(lastNodeCaption = @"Module Init Func Pointers") 
                            location:section_64->offset + imageOffset
                              length:section_64->size]; break;
          
        case S_MOD_TERM_FUNC_POINTERS:
          [self createPointers64Node:sectionNode 
                             caption:(lastNodeCaption = @"Module Term Func Pointers") 
                            location:section_64->offset + imageOffset
                              length:section_64->size]; break;
          
        case S_LAZY_SYMBOL_POINTERS:
          [self createIndPointers64Node:sectionNode 
                                caption:(lastNodeCaption = @"Lazy Symbol Pointers")
                               location:section_64->offset + imageOffset
                                 length:section_64->size]; break;
          
        case S_NON_LAZY_SYMBOL_POINTERS:
          [self createIndPointers64Node:sectionNode 
                                caption:(lastNodeCaption = @"Non-Lazy Symbol Pointers")
                               location:section_64->offset + imageOffset
                                 length:section_64->size]; break;
          
        case S_LAZY_DYLIB_SYMBOL_POINTERS:
          [self createIndPointers64Node:sectionNode 
                                caption:(lastNodeCaption = @"Lazy Dylib Symbol Pointers")
                               location:section_64->offset + imageOffset
                                 length:section_64->size]; break;
          
        case S_SYMBOL_STUBS:
          [self createIndStubs64Node:sectionNode 
                             caption:(lastNodeCaption = @"Symbol Stubs")
                            location:section_64->offset + imageOffset
                              length:section_64->size
                              stride:section_64->reserved2]; break;
          
        default:;
      }
    }
    @catch(NSException * exception)
    {
      [self printException:exception caption:lastNodeCaption];
    }
  }
  
}

//-----------------------------------------------------------------------------
-(void)processEHFrames
{
  // dylib stubs have no section
  if ([self isDylibStub] == YES)
  {
    return;
  }
  
  NSString * lastNodeCaption;
  
  for (SectionVector::iterator sectIter = find_if(++sections.begin(), sections.end(), CompareSectionByName<struct section>("__eh_frame"));
       sectIter != sections.end();
       sectIter = find_if(++sectIter, sections.end(), CompareSectionByName<struct section>("__eh_frame")))
  {
    struct section const * section = *sectIter;
    
    MVNode * sectionNode = [self findNodeByUserInfo:[self userInfoForSection:section]];
    // there is no valid exception data
    if (sectionNode == nil) 
    {
      return;
    }
    
    /* The .eh_frame section shall contain 1 or more Call Frame Information (CFI) records. 
     * The number of records present shall be determined by size of the section as contained in the section header.
     * Each CFI record contains a Common Information Entry (CIE) record followed by 1 or more Frame Description Entry (FDE) records. 
     * Both CIEs and FDEs shall be aligned to an addressing unit sized boundary.
     */
    
    @try
    {
      uint32_t location = section->offset + imageOffset;
      do
      {
        NSRange range = NSMakeRange(location,0);
        uint32_t length = [dataController read_uint32:range];
        uint32_t cieID = [dataController read_uint32:range];
        
        if (cieID == 0)
        {
          uint32_t CIE_addr = [self fileOffsetToRVA:location];
          [self createCFINode:sectionNode
                      caption:(lastNodeCaption = [NSString stringWithFormat:@"Call Frame %@", [self findSymbolAtRVA:CIE_addr]])
                     location:location
                       length:section->offset + imageOffset + section->size - location];  // upper bound
        }
        location += length + /*length itself */ sizeof(uint32_t);
      } while (location - section->offset - imageOffset < section->size);
    }
    @catch(NSException * exception)
    {
      [self printException:exception caption:lastNodeCaption];
    }
  }
}

//-----------------------------------------------------------------------------
-(void)processEHFrames64
{
  // dylib stubs have no section
  if ([self isDylibStub] == YES)
  {
    return;
  }
  
  NSString * lastNodeCaption;
  
  for (Section64Vector::iterator sectIter = find_if(++sections_64.begin(), sections_64.end(), CompareSectionByName<struct section_64>("__eh_frame"));
       sectIter != sections_64.end();
       sectIter = find_if(++sectIter, sections_64.end(), CompareSectionByName<struct section_64>("__eh_frame")))
  {
    struct section_64 const * section_64 = *sectIter;
    
    MVNode * sectionNode = [self findNodeByUserInfo:[self userInfoForSection64:section_64]];
    // there is no valid exception data
    if (sectionNode == nil) 
    {
      return;
    }
    
    /* The .eh_frame section shall contain 1 or more Call Frame Information (CFI) records. 
     * The number of records present shall be determined by size of the section as contained in the section header.
     * Each CFI record contains a Common Information Entry (CIE) record followed by 1 or more Frame Description Entry (FDE) records. 
     * Both CIEs and FDEs shall be aligned to an addressing unit sized boundary.
     */
    
    @try
    {
      uint32_t location = section_64->offset + imageOffset;
      do
      {
        NSRange range = NSMakeRange(location,0);
        uint32_t length = [dataController read_uint32:range];
        uint32_t cieID = [dataController read_uint32:range];
        
        if (cieID == 0)
        {
          uint64_t CIE_addr = [self fileOffsetToRVA64:location];
          [self createCFINode:sectionNode
                      caption:(lastNodeCaption = [NSString stringWithFormat:@"Call Frame %@", [self findSymbolAtRVA64:CIE_addr]])
                     location:location
                       length:section_64->offset + imageOffset + section_64->size - location]; // upper bound
        }
        location += length + /*length itself */ sizeof(uint32_t);
      } while (location - section_64->offset - imageOffset < section_64->size);
    }
    @catch(NSException * exception)
    {
      [self printException:exception caption:lastNodeCaption];
    }
  }
}

//-----------------------------------------------------------------------------
-(void)processLSDA
{
  // dylib stubs have no section
  if ([self isDylibStub] == YES)
  {
    return;
  }
  
  NSString * lastNodeCaption;
  
  for (SectionVector::iterator sectIter = find_if(++sections.begin(), sections.end(), CompareSectionByName<struct section>("__gcc_except_tab"));
       sectIter != sections.end();
       sectIter = find_if(++sectIter, sections.end(), CompareSectionByName<struct section>("__gcc_except_tab")))
  {
    struct section const * section = *sectIter;
    
    MVNode * sectionNode = [self findNodeByUserInfo:[self userInfoForSection:section]];
    NSParameterAssert(sectionNode != nil);
    if (sectionNode == nil)
    { 
      return;
    }
    
    @try 
    {
      for (ExceptionFrameMap::iterator ehFrameIter = lsdaInfo.begin(); ehFrameIter != lsdaInfo.end();)
      {
        uint32_t lsdaAddr = ehFrameIter->first;
        uint32_t frameAddr = ehFrameIter->second;
        
        uint32_t location = [self RVAToFileOffset:lsdaAddr];
        
        uint32_t length = (++ehFrameIter != lsdaInfo.end() 
                           ? [self RVAToFileOffset:ehFrameIter->first]
                           : imageOffset + section->offset + section->size) - location;
        
        [self createLSDANode:sectionNode 
                     caption:(lastNodeCaption = [NSString stringWithFormat:@"LSDA %@",[self findSymbolAtRVA:lsdaAddr]])
                    location:location
                      length:length
              eh_frame_begin:frameAddr];
      }
    }      
    @catch(NSException * exception)
    {
      [self printException:exception caption:lastNodeCaption];
    }
  }
}

//-----------------------------------------------------------------------------
-(void)processLSDA64
{
  // dylib stubs have no section
  if ([self isDylibStub] == YES)
  {
    return;
  }
  
  NSString * lastNodeCaption;
  
  for (Section64Vector::iterator sectIter = find_if(++sections_64.begin(), sections_64.end(), CompareSectionByName<struct section_64>("__gcc_except_tab"));
       sectIter != sections_64.end();
       sectIter = find_if(++sectIter, sections_64.end(), CompareSectionByName<struct section_64>("__gcc_except_tab")))
  {
    struct section_64 const * section_64 = *sectIter;
    
    MVNode * sectionNode = [self findNodeByUserInfo:[self userInfoForSection64:section_64]];
    NSParameterAssert(sectionNode != nil);
    if (sectionNode == nil)
    {
      return;
    }
    
    @try 
    {
      for (ExceptionFrameMap::iterator ehFrameIter = lsdaInfo.begin(); ehFrameIter != lsdaInfo.end();)
      {
        uint64_t lsdaAddr = ehFrameIter->first;
        uint64_t frameAddr = ehFrameIter->second;
        
        uint32_t location = [self RVA64ToFileOffset:lsdaAddr];
        
        uint32_t length = (++ehFrameIter != lsdaInfo.end() 
                           ? [self RVA64ToFileOffset:ehFrameIter->first]
                           : section_64->offset + section_64->size) - location;
        
        [self createLSDANode:sectionNode 
                     caption:(lastNodeCaption = [NSString stringWithFormat:@"LSDA %@",[self findSymbolAtRVA64:lsdaAddr]])
                    location:location
                      length:length
              eh_frame_begin:frameAddr];
      }
    }      
    @catch(NSException * exception)
    {
      [self printException:exception caption:lastNodeCaption];
    }
  }
}

//-----------------------------------------------------------------------------
-(void)processObjcSections
{
  PointerVector objcClassPointers;
  PointerVector objcClassReferences;
  PointerVector objcSuperReferences;
  PointerVector objcCategoryPointers;
  PointerVector objcProtocolPointers;
  
  NSString * lastNodeCaption;
  MVNode * sectionNode;
  struct section const * section;
  bool hasObjCModules = false; // objC version detector
  
  @try 
  {
    // first Objective-C ABI
    section = [self findSectionByName:"__module_info" andSegment:"__OBJC"];
    if ((sectionNode = [self findNodeByUserInfo:[self userInfoForSection:section]]))
    {
      hasObjCModules = true;
      [self createObjCModulesNode:sectionNode 
                          caption:(lastNodeCaption = @"ObjC Modules") 
                         location:section->offset + imageOffset 
                           length:section->size];
    }
    
    section = [self findSectionByName:"__class_ext" andSegment:"__OBJC"];
    if ((sectionNode = [self findNodeByUserInfo:[self userInfoForSection:section]]))
    {
      [self createObjCClassExtNode:sectionNode 
                           caption:(lastNodeCaption = @"ObjC Class Extensions") 
                          location:section->offset + imageOffset 
                            length:section->size];
    }
    
    section = [self findSectionByName:"__protocol_ext" andSegment:"__OBJC"];
    if ((sectionNode = [self findNodeByUserInfo:[self userInfoForSection:section]]))
    {
      [self createObjCProtocolExtNode:sectionNode 
                              caption:(lastNodeCaption = @"ObjC Protocol Extensions") 
                             location:section->offset + imageOffset 
                               length:section->size];
    }
    
    // second Objective-C ABI
    if (hasObjCModules == false)
    {
      section = [self findSectionByName:"__category_list" andSegment:"__OBJC2"];
      if (section == NULL)
        section = [self findSectionByName:"__objc_catlist" andSegment:"__DATA"];
      if ((sectionNode = [self findNodeByUserInfo:[self userInfoForSection:section]]))
      {
        [self createObjC2PointerListNode:sectionNode
                                 caption:(lastNodeCaption = @"ObjC2 Category List")
                                location:section->offset + imageOffset
                                  length:section->size
                                pointers:objcCategoryPointers];
      }

      section = [self findSectionByName:"__class_list" andSegment:"__OBJC2"];
      if (section == NULL)
        section = [self findSectionByName:"__objc_classlist" andSegment:"__DATA"];
      if ((sectionNode = [self findNodeByUserInfo:[self userInfoForSection:section]]))
      {
        [self createObjC2PointerListNode:sectionNode 
                                 caption:(lastNodeCaption = @"ObjC2 Class List") 
                                location:section->offset + imageOffset 
                                  length:section->size
                                pointers:objcClassPointers];
      }
      
      section = [self findSectionByName:"__class_refs" andSegment:"__OBJC2"];
      if (section == NULL)
        section = [self findSectionByName:"__objc_classrefs" andSegment:"__DATA"];
      if ((sectionNode = [self findNodeByUserInfo:[self userInfoForSection:section]]))
      {
        [self createObjC2PointerListNode:sectionNode 
                                 caption:(lastNodeCaption = @"ObjC2 References") 
                                location:section->offset + imageOffset 
                                  length:section->size
                                pointers:objcClassReferences];
      }
      
      section = [self findSectionByName:"__super_refs" andSegment:"__OBJC2"];
      if (section == NULL)
        section = [self findSectionByName:"__objc_superrefs" andSegment:"__DATA"];
      if ((sectionNode = [self findNodeByUserInfo:[self userInfoForSection:section]]))
      {
        [self createObjC2PointerListNode:sectionNode 
                                 caption:(lastNodeCaption = @"ObjC2 References") 
                                location:section->offset + imageOffset 
                                  length:section->size
                                pointers:objcSuperReferences];
      }
      
      section = [self findSectionByName:"__protocol_list" andSegment:"__OBJC2"];
      if (section == NULL)
        section = [self findSectionByName:"__objc_protolist" andSegment:"__DATA"];
      if ((sectionNode = [self findNodeByUserInfo:[self userInfoForSection:section]]))
      {
        [self createObjC2PointerListNode:sectionNode 
                                 caption:(lastNodeCaption = @"ObjC2 Pointer List")
                                location:section->offset + imageOffset 
                                  length:section->size
                                pointers:objcProtocolPointers];
      }
      
      section = [self findSectionByName:"__message_refs" andSegment:"__OBJC2"];
      if (section == NULL)
        section = [self findSectionByName:"__objc_msgrefs" andSegment:"__DATA"];
      if ((sectionNode = [self findNodeByUserInfo:[self userInfoForSection:section]]))
      {
        [self createObjC2MsgRefsNode:sectionNode 
                             caption:(lastNodeCaption = @"ObjC2 Message References") 
                            location:section->offset + imageOffset 
                              length:section->size];
      }
    } // if (hasObjcModules == false)
    
    section = [self findSectionByName:"__image_info" andSegment:"__OBJC"];
    if (section == NULL)
      section = [self findSectionByName:"__objc_imageinfo" andSegment:"__DATA"];
    if ((sectionNode = [self findNodeByUserInfo:[self userInfoForSection:section]]))
    {
      [self createObjCImageInfoNode:sectionNode 
                            caption:(lastNodeCaption = @"ObjC2 Image Info") 
                           location:section->offset + imageOffset 
                             length:section->size];
    }
    
    section = [self findSectionByName:"__cfstring" andSegment:NULL];
    if ((sectionNode = [self findNodeByUserInfo:[self userInfoForSection:section]]))
    {
      [self createObjCCFStringsNode:sectionNode 
                            caption:(lastNodeCaption = @"ObjC CFStrings") 
                           location:section->offset + imageOffset 
                             length:section->size];
    }
  }
  @catch(NSException * exception)
  {
    [self printException:exception caption:lastNodeCaption];
  }
  
  
  
  @try
  {
    [self parseObjC2ClassPointers:&objcClassPointers
                 CategoryPointers:&objcCategoryPointers
                 ProtocolPointers:&objcProtocolPointers];
  }
  @catch(NSException * exception)
  {
    [self printException:exception caption:lastNodeCaption];
  }
}

//-----------------------------------------------------------------------------
-(void)processObjcSections64
{
  Pointer64Vector objcClassPointers;
  Pointer64Vector objcClassReferences;
  Pointer64Vector objcSuperReferences;
  Pointer64Vector objcCategoryPointers;
  Pointer64Vector objcProtocolPointers;
  
  NSString * lastNodeCaption;
  MVNode * sectionNode;
  struct section_64 const * section_64;
  
  @try 
  {
    section_64 = [self findSection64ByName:"__class_list" andSegment:"__OBJC2"];
    if (section_64 == NULL)
      section_64 = [self findSection64ByName:"__objc_classlist" andSegment:"__DATA"];
    if ((sectionNode = [self findNodeByUserInfo:[self userInfoForSection64:section_64]]))
    {
      [self createObjC2Pointer64ListNode:sectionNode 
                                 caption:(lastNodeCaption = @"ObjC2 Class List") 
                                location:section_64->offset + imageOffset 
                                  length:section_64->size
                                pointers:objcClassPointers];
    }

    section_64 = [self findSection64ByName:"__class_refs" andSegment:"__OBJC2"];
    if (section_64 == NULL)
      section_64 = [self findSection64ByName:"__objc_classrefs" andSegment:"__DATA"];
    if ((sectionNode = [self findNodeByUserInfo:[self userInfoForSection64:section_64]]))
    {
      [self createObjC2Pointer64ListNode:sectionNode 
                                 caption:(lastNodeCaption = @"ObjC2 References") 
                                location:section_64->offset + imageOffset 
                                  length:section_64->size
                                pointers:objcClassReferences];
    }
    
    section_64 = [self findSection64ByName:"__super_refs" andSegment:"__OBJC2"];
    if (section_64 == NULL)
      section_64 = [self findSection64ByName:"__objc_superrefs" andSegment:"__DATA"];
    if ((sectionNode = [self findNodeByUserInfo:[self userInfoForSection64:section_64]]))
    {
      [self createObjC2Pointer64ListNode:sectionNode 
                                 caption:(lastNodeCaption = @"ObjC2 References") 
                                location:section_64->offset + imageOffset 
                                  length:section_64->size
                                pointers:objcSuperReferences];
    }

    section_64 = [self findSection64ByName:"__category_list" andSegment:"__OBJC2"];
    if (section_64 == NULL)
      section_64 = [self findSection64ByName:"__objc_catlist" andSegment:"__DATA"];
    if ((sectionNode = [self findNodeByUserInfo:[self userInfoForSection64:section_64]]))
    {
      [self createObjC2Pointer64ListNode:sectionNode 
                                 caption:(lastNodeCaption = @"ObjC2 Category List")
                                location:section_64->offset + imageOffset 
                                  length:section_64->size
                                pointers:objcCategoryPointers];
    }
    
    section_64 = [self findSection64ByName:"__protocol_list" andSegment:"__OBJC2"];
    if (section_64 == NULL)
      section_64 = [self findSection64ByName:"__objc_protolist" andSegment:"__DATA"];
    if ((sectionNode = [self findNodeByUserInfo:[self userInfoForSection64:section_64]]))
    {
      [self createObjC2Pointer64ListNode:sectionNode 
                                 caption:(lastNodeCaption = @"ObjC2 Pointer List")
                                location:section_64->offset + imageOffset 
                                  length:section_64->size
                                pointers:objcProtocolPointers];
    }
    
    section_64 = [self findSection64ByName:"__message_refs" andSegment:"__OBJC2"];
    if (section_64 == NULL)
      section_64 = [self findSection64ByName:"__objc_msgrefs" andSegment:"__DATA"];
    if ((sectionNode = [self findNodeByUserInfo:[self userInfoForSection64:section_64]]))
    {
      [self createObjC2MsgRefs64Node:sectionNode 
                             caption:(lastNodeCaption = @"ObjC2 Message References") 
                            location:section_64->offset + imageOffset 
                              length:section_64->size];
    }
    
    section_64 = [self findSection64ByName:"__image_info" andSegment:"__OBJC"];
    if (section_64 == NULL)
      section_64 = [self findSection64ByName:"__objc_imageinfo" andSegment:"__DATA"];
    if ((sectionNode = [self findNodeByUserInfo:[self userInfoForSection64:section_64]]))
    {
      [self createObjCImageInfoNode:sectionNode 
                            caption:(lastNodeCaption = @"ObjC2 Image Info") 
                           location:section_64->offset + imageOffset 
                             length:section_64->size];
    }
    
    section_64 = [self findSection64ByName:"__cfstring" andSegment:NULL];
    if ((sectionNode = [self findNodeByUserInfo:[self userInfoForSection64:section_64]]))
    {
      [self createObjCCFStrings64Node:sectionNode 
                              caption:(lastNodeCaption = @"ObjC CFStrings") 
                             location:section_64->offset + imageOffset 
                               length:section_64->size];
    }
  }
  @catch(NSException * exception)
  {
    [self printException:exception caption:lastNodeCaption];
  }

  
  @try
  {
    [self parseObjC2Class64Pointers:&objcClassPointers
                 Category64Pointers:&objcCategoryPointers
                 Protocol64Pointers:&objcProtocolPointers];
  }
  @catch(NSException * exception)
  {
    [self printException:exception caption:lastNodeCaption];
  }
  
}

//-----------------------------------------------------------------------------
- (void)processCodeSections
{
  // find related load commands
  struct dysymtab_command const * dysymtab_command = NULL;
  for (CommandVector::const_iterator cmdIter = commands.begin(); cmdIter != commands.end(); ++cmdIter)
  {
    struct load_command const * load_command = *cmdIter;
    switch (load_command->cmd)
    {
      case LC_DYSYMTAB: dysymtab_command = (struct dysymtab_command const *)load_command; break;
      default: ; // not interested
    }
  }
  

  NSString * lastNodeCaption;
  
  for (SectionVector::const_iterator sectIter = ++sections.begin(); sectIter != sections.end(); ++sectIter)
  {
    struct section const * section = *sectIter;
    MVNode * sectionNode = [self findNodeByUserInfo:[self userInfoForSection:section]];
    if (sectionNode == nil)
    {
      continue;
    }
    
    @try 
    {
      if ((section->flags & S_ATTR_PURE_INSTRUCTIONS) && (section->flags & SECTION_TYPE) != S_SYMBOL_STUBS)
      {
        [self createTextNode:sectionNode 
                     caption:(lastNodeCaption = @"Assembly") 
                    location:section->offset + imageOffset 
                      length:section->size
                      reloff:section->reloff + imageOffset
                      nreloc:section->nreloc
                   extreloff:dysymtab_command ? dysymtab_command->extreloff : 0
                     nextrel:dysymtab_command ? dysymtab_command->nextrel : 0
                   locreloff:dysymtab_command ? dysymtab_command->locreloff : 0
                     nlocrel:dysymtab_command ? dysymtab_command->nlocrel : 0];
      }
    }
    @catch(NSException * exception)
    {
      [self printException:exception caption:lastNodeCaption];
    }
  }
}

//-----------------------------------------------------------------------------
- (void)processCodeSections64
{
  // find related load commands
  struct dysymtab_command const * dysymtab_command = NULL;
  for (CommandVector::const_iterator cmdIter = commands.begin(); cmdIter != commands.end(); ++cmdIter)
  {
    struct load_command const * load_command = *cmdIter;
    switch (load_command->cmd)
    {
      case LC_DYSYMTAB: dysymtab_command = (struct dysymtab_command const *)load_command; break;
      default: ; // not interested
    }
  }
  
  
  NSString * lastNodeCaption;
  
  for (Section64Vector::const_iterator sectIter = ++sections_64.begin(); sectIter != sections_64.end(); ++sectIter)
  {
    struct section_64 const * section_64 = *sectIter;
    MVNode * sectionNode = [self findNodeByUserInfo:[self userInfoForSection64:section_64]];
    if (sectionNode == nil)
    {
      continue;
    }
    
    @try 
    {
      if ((section_64->flags & S_ATTR_PURE_INSTRUCTIONS) && (section_64->flags & SECTION_TYPE) != S_SYMBOL_STUBS)
      {
        [self createTextNode:sectionNode 
                     caption:(lastNodeCaption = @"Assembly") 
                    location:section_64->offset + imageOffset 
                      length:section_64->size
                      reloff:section_64->reloff + imageOffset
                      nreloc:section_64->nreloc
                   extreloff:dysymtab_command ? dysymtab_command->extreloff : 0
                     nextrel:dysymtab_command ? dysymtab_command->nextrel : 0
                   locreloff:dysymtab_command ? dysymtab_command->locreloff : 0
                     nlocrel:dysymtab_command ? dysymtab_command->nlocrel : 0];
      }
    }
    @catch(NSException * exception)
    {
      [self printException:exception caption:lastNodeCaption];
    }
  }
}

//-----------------------------------------------------------------------------
- (void)processSectionRelocs
{
  // find Relocations node
  MVNode * relocsNode = [self findNodeByUserInfo:[self userInfoForRelocs]];
  if (relocsNode == nil)
  {
    return;
  }
  
  NSString * lastNodeCaption;
  @try
  {
    for (SectionVector::const_iterator sectIter = ++sections.begin(); sectIter != sections.end(); ++sectIter)
    {
      struct section const * section = *sectIter;
      if (section->nreloc > 0)
      {
        [self createRelocNode:relocsNode 
                      caption:(lastNodeCaption = [NSString stringWithFormat:@"(%s,%s)",
                                                  string(section->segname,16).c_str(),
                                                  string(section->sectname,16).c_str()])
                     location:section->reloff + imageOffset
                       length:section->nreloc * sizeof(struct relocation_info)
                  baseAddress:section->addr];
      }
    }
  }
  @catch(NSException * exception)
  {
    [self printException:exception caption:lastNodeCaption];
  }
}

//-----------------------------------------------------------------------------
- (void)processSectionRelocs64
{
  // find Relocations node
  MVNode * relocsNode = [self findNodeByUserInfo:[self userInfoForRelocs]];
  if (relocsNode == nil)
  {
    return;
  }
  
  NSString * lastNodeCaption;
  @try
  {  
    for (Section64Vector::const_iterator sectIter = ++sections_64.begin(); sectIter != sections_64.end(); ++sectIter)
    {
      struct section_64 const * section_64 = *sectIter;
      if (section_64->nreloc > 0)
      {
        [self createReloc64Node:relocsNode 
                        caption:(lastNodeCaption = [NSString stringWithFormat:@"(%s,%s)",
                                                    string(section_64->segname,16).c_str(),
                                                    string(section_64->sectname,16).c_str()])
                       location:section_64->reloff + imageOffset
                         length:section_64->nreloc * sizeof(struct relocation_info)
                    baseAddress:section_64->addr];
      }
    }
  }
  @catch(NSException * exception)
  {
    [self printException:exception caption:lastNodeCaption];
  }
}

//-----------------------------------------------------------------------------
- (MVNode *)createMachONode:(MVNode *)parent
                    caption:(NSString *)caption
                   location:(uint32_t)location
                mach_header:(struct mach_header const *)mach_header
{
  MVNodeSaver nodeSaver;
  MVNode * node = [parent insertChildWithDetails:caption location:location length:sizeof(struct mach_header) saver:nodeSaver]; 
  
  NSRange range = NSMakeRange(location,0);
  NSString * lastReadHex;
  
  [dataController read_uint32:range lastReadHex:&lastReadHex];
  [node.details appendRow:[NSString stringWithFormat:@"%.8lX", range.location]
                         :lastReadHex
                         :@"Magic Number"
                         :mach_header->magic == MH_MAGIC ? @"MH_MAGIC" :
                          mach_header->magic == MH_CIGAM ? @"MH_CIGAM" : @"???"];
  
  [dataController read_uint32:range lastReadHex:&lastReadHex];
  [node.details appendRow:[NSString stringWithFormat:@"%.8lX", range.location]
                         :lastReadHex
                         :@"CPU Type"
                         :mach_header->cputype == CPU_TYPE_ANY ? @"CPU_TYPE_ANY" :
                          mach_header->cputype == CPU_TYPE_I386 ? @"CPU_TYPE_I386" :
                          mach_header->cputype == CPU_TYPE_ARM ? @"CPU_TYPE_ARM" :
                          mach_header->cputype == CPU_TYPE_POWERPC ? @"CPU_TYPE_POWERPC" : @"???"];
  
  [dataController read_uint32:range lastReadHex:&lastReadHex];
  [node.details appendRow:[NSString stringWithFormat:@"%.8lX", range.location]
                         :lastReadHex
                         :@"CPU SubType"
                         :@""];
   
  if ((mach_header->cpusubtype & CPU_SUBTYPE_LIB64) == CPU_SUBTYPE_LIB64) [node.details appendRow:@"":@"":@"80000000":@"CPU_SUBTYPE_LIB64"];
  
  if (mach_header->cputype == CPU_TYPE_ARM)
  {
    if ((mach_header->cpusubtype & ~CPU_SUBTYPE_MASK) == CPU_SUBTYPE_ARM_ALL)   [node.details appendRow:@"":@"":@"00000000":@"CPU_SUBTYPE_ARM_ALL"];
    if ((mach_header->cpusubtype & ~CPU_SUBTYPE_MASK) == CPU_SUBTYPE_ARM_V4T)   [node.details appendRow:@"":@"":@"00000005":@"CPU_SUBTYPE_ARM_V4T"];
    if ((mach_header->cpusubtype & ~CPU_SUBTYPE_MASK) == CPU_SUBTYPE_ARM_V6)    [node.details appendRow:@"":@"":@"00000006":@"CPU_SUBTYPE_ARM_V6"];
    if ((mach_header->cpusubtype & ~CPU_SUBTYPE_MASK) == CPU_SUBTYPE_ARM_V5TEJ) [node.details appendRow:@"":@"":@"00000007":@"CPU_SUBTYPE_ARM_V5TEJ"];
    if ((mach_header->cpusubtype & ~CPU_SUBTYPE_MASK) == CPU_SUBTYPE_ARM_XSCALE)[node.details appendRow:@"":@"":@"00000008":@"CPU_SUBTYPE_ARM_XSCALE"];
    if ((mach_header->cpusubtype & ~CPU_SUBTYPE_MASK) == CPU_SUBTYPE_ARM_V7)    [node.details appendRow:@"":@"":@"00000009":@"CPU_SUBTYPE_ARM_V7"];
    if ((mach_header->cpusubtype & ~CPU_SUBTYPE_MASK) == CPU_SUBTYPE_ARM_V7F)   [node.details appendRow:@"":@"":@"0000000A":@"CPU_SUBTYPE_ARM_V7F (Cortex A9)"];
    if ((mach_header->cpusubtype & ~CPU_SUBTYPE_MASK) == CPU_SUBTYPE_ARM_V7S)   [node.details appendRow:@"":@"":@"0000000B":@"CPU_SUBTYPE_ARM_V7S (Swift)"];
    if ((mach_header->cpusubtype & ~CPU_SUBTYPE_MASK) == CPU_SUBTYPE_ARM_V7K)   [node.details appendRow:@"":@"":@"0000000C":@"CPU_SUBTYPE_ARM_V7K (Kirkwood40)"];
    if ((mach_header->cpusubtype & ~CPU_SUBTYPE_MASK) == CPU_SUBTYPE_ARM_V6M)   [node.details appendRow:@"":@"":@"0000000E":@"CPU_SUBTYPE_ARM_V6M"];
    if ((mach_header->cpusubtype & ~CPU_SUBTYPE_MASK) == CPU_SUBTYPE_ARM_V7M)   [node.details appendRow:@"":@"":@"0000000F":@"CPU_SUBTYPE_ARM_V7M"];
    if ((mach_header->cpusubtype & ~CPU_SUBTYPE_MASK) == CPU_SUBTYPE_ARM_V7EM)  [node.details appendRow:@"":@"":@"00000010":@"CPU_SUBTYPE_ARM_V7EM"];
    if ((mach_header->cpusubtype & ~CPU_SUBTYPE_MASK) == CPU_SUBTYPE_ARM_V8)    [node.details appendRow:@"":@"":@"0000000D":@"CPU_SUBTYPE_ARM_V8"];
  }
  else if (mach_header->cputype == CPU_TYPE_I386)
  {
    if ((mach_header->cpusubtype & ~CPU_SUBTYPE_MASK) == CPU_SUBTYPE_I386_ALL) [node.details appendRow:@"":@"":@"00000003":@"CPU_SUBTYPE_I386_ALL"];
  }
  else if (mach_header->cputype == CPU_TYPE_ANY)
  {
    if ((mach_header->cpusubtype & ~CPU_SUBTYPE_MASK) == CPU_SUBTYPE_MULTIPLE) [node.details appendRow:@"":@"":@"FFFFFFFF":@"CPU_SUBTYPE_MULTIPLE"];
    if ((mach_header->cpusubtype & ~CPU_SUBTYPE_MASK) == CPU_SUBTYPE_LITTLE_ENDIAN) [node.details appendRow:@"":@"":@"00000000":@"CPU_SUBTYPE_LITTLE_ENDIAN"];
    if ((mach_header->cpusubtype & ~CPU_SUBTYPE_MASK) == CPU_SUBTYPE_BIG_ENDIAN) [node.details appendRow:@"":@"":@"00000001":@"CPU_SUBTYPE_BIG_ENDIAN"];
  }
   
  [dataController read_uint32:range lastReadHex:&lastReadHex];
  [node.details appendRow:[NSString stringWithFormat:@"%.8lX", range.location]
                         :lastReadHex
                         :@"File Type"
                         :mach_header->filetype == MH_OBJECT ? @"MH_OBJECT" :
                          mach_header->filetype == MH_EXECUTE ? @"MH_EXECUTE" :
                          mach_header->filetype == MH_FVMLIB ? @"MH_FVMLIB" :
                          mach_header->filetype == MH_CORE ? @"MH_CORE" :
                          mach_header->filetype == MH_PRELOAD ? @"MH_PRELOAD" :
                          mach_header->filetype == MH_DYLIB ? @"MH_DYLIB" :
                          mach_header->filetype == MH_DYLINKER ? @"MH_DYLINKER" :
                          mach_header->filetype == MH_BUNDLE ? @"MH_BUNDLE" :
                          mach_header->filetype == MH_DYLIB_STUB ? @"MH_DYLIB_STUB" :
                          mach_header->filetype == MH_DSYM ? @"MH_DSYM" : 
                          mach_header->filetype == MH_KEXT_BUNDLE ? @"MH_KEXT_BUNDLE" : @"???"];
  
  [dataController read_uint32:range lastReadHex:&lastReadHex];
  [node.details appendRow:[NSString stringWithFormat:@"%.8lX", range.location]
                         :lastReadHex
                         :@"Number of Load Commands"
                         :[NSString stringWithFormat:@"%u", mach_header->ncmds]];
  
  [dataController read_uint32:range lastReadHex:&lastReadHex];
  [node.details appendRow:[NSString stringWithFormat:@"%.8lX", range.location]
                         :lastReadHex
                         :@"Size of Load Commands"
                         :[NSString stringWithFormat:@"%u", mach_header->sizeofcmds]];
  
  [dataController read_uint32:range lastReadHex:&lastReadHex];
  [node.details appendRow:[NSString stringWithFormat:@"%.8lX", range.location]
                         :lastReadHex
                         :@"Flags"
                         :@""];
  
  if (mach_header->flags & MH_NOUNDEFS)                [node.details appendRow:@"":@"":@"00000001":@"MH_NOUNDEFS"];
  if (mach_header->flags & MH_INCRLINK)                [node.details appendRow:@"":@"":@"00000002":@"MH_INCRLINK"];
  if (mach_header->flags & MH_DYLDLINK)                [node.details appendRow:@"":@"":@"00000004":@"MH_DYLDLINK"];
  if (mach_header->flags & MH_BINDATLOAD)              [node.details appendRow:@"":@"":@"00000008":@"MH_BINDATLOAD"];
  if (mach_header->flags & MH_PREBOUND)                [node.details appendRow:@"":@"":@"00000010":@"MH_PREBOUND"];
  if (mach_header->flags & MH_SPLIT_SEGS)              [node.details appendRow:@"":@"":@"00000020":@"MH_SPLIT_SEGS"];
  if (mach_header->flags & MH_LAZY_INIT)               [node.details appendRow:@"":@"":@"00000040":@"MH_LAZY_INIT"];
  if (mach_header->flags & MH_TWOLEVEL)                [node.details appendRow:@"":@"":@"00000080":@"MH_TWOLEVEL"];
  if (mach_header->flags & MH_FORCE_FLAT)              [node.details appendRow:@"":@"":@"00000100":@"MH_FORCE_FLAT"];
  if (mach_header->flags & MH_NOMULTIDEFS)             [node.details appendRow:@"":@"":@"00000200":@"MH_NOMULTIDEFS"];
  if (mach_header->flags & MH_NOFIXPREBINDING)         [node.details appendRow:@"":@"":@"00000400":@"MH_NOFIXPREBINDING"];
  if (mach_header->flags & MH_PREBINDABLE)             [node.details appendRow:@"":@"":@"00000800":@"MH_PREBINDABLE"];
  if (mach_header->flags & MH_ALLMODSBOUND)            [node.details appendRow:@"":@"":@"00001000":@"MH_ALLMODSBOUND"];
  if (mach_header->flags & MH_SUBSECTIONS_VIA_SYMBOLS) [node.details appendRow:@"":@"":@"00002000":@"MH_SUBSECTIONS_VIA_SYMBOLS"];
  if (mach_header->flags & MH_CANONICAL)               [node.details appendRow:@"":@"":@"00004000":@"MH_CANONICAL"];
  if (mach_header->flags & MH_WEAK_DEFINES)            [node.details appendRow:@"":@"":@"00008000":@"MH_WEAK_DEFINES"];
  if (mach_header->flags & MH_BINDS_TO_WEAK)           [node.details appendRow:@"":@"":@"00010000":@"MH_BINDS_TO_WEAK"];
  if (mach_header->flags & MH_ALLOW_STACK_EXECUTION)   [node.details appendRow:@"":@"":@"00020000":@"MH_ALLOW_STACK_EXECUTION"];
  if (mach_header->flags & MH_ROOT_SAFE)               [node.details appendRow:@"":@"":@"00040000":@"MH_ROOT_SAFE"];
  if (mach_header->flags & MH_SETUID_SAFE)             [node.details appendRow:@"":@"":@"00080000":@"MH_SETUID_SAFE"];
  if (mach_header->flags & MH_NO_REEXPORTED_DYLIBS)    [node.details appendRow:@"":@"":@"00100000":@"MH_NO_REEXPORTED_DYLIBS"];
  if (mach_header->flags & MH_PIE)                     [node.details appendRow:@"":@"":@"00200000":@"MH_PIE"];
  if (mach_header->flags & MH_DEAD_STRIPPABLE_DYLIB)   [node.details appendRow:@"":@"":@"00400000":@"MH_DEAD_STRIPPABLE_DYLIB"];
  if (mach_header->flags & MH_HAS_TLV_DESCRIPTORS)     [node.details appendRow:@"":@"":@"00800000":@"MH_HAS_TLV_DESCRIPTORS"];
  if (mach_header->flags & MH_NO_HEAP_EXECUTION)       [node.details appendRow:@"":@"":@"01000000":@"MH_NO_HEAP_EXECUTION"];
  
  return node;
}
//-----------------------------------------------------------------------------

- (MVNode *)createMachO64Node:(MVNode *)parent
                      caption:(NSString *)caption
                     location:(uint32_t)location
               mach_header_64:(struct mach_header_64 const *)mach_header_64
{
  MVNodeSaver nodeSaver;
  MVNode * node = [parent insertChildWithDetails:caption location:location length:sizeof(struct mach_header_64) saver:nodeSaver]; 
  
  NSRange range = NSMakeRange(location,0);
  NSString * lastReadHex;
  
  [dataController read_uint32:range lastReadHex:&lastReadHex];
  [node.details appendRow:[NSString stringWithFormat:@"%.8lX", range.location]
                         :lastReadHex
                         :@"Magic Number"
                         :mach_header_64->magic == MH_MAGIC_64 ? @"MH_MAGIC_64" :
                          mach_header_64->magic == MH_CIGAM_64 ? @"MH_CIGAM_64" : @"???"];
  
  [dataController read_uint32:range lastReadHex:&lastReadHex];
  [node.details appendRow:[NSString stringWithFormat:@"%.8lX", range.location]
                         :lastReadHex
                         :@"CPU Type"
                         :mach_header_64->cputype == CPU_TYPE_ANY ? @"CPU_TYPE_ANY" :
                          mach_header_64->cputype == CPU_TYPE_POWERPC64 ? @"CPU_TYPE_POWERPC64" :
                          mach_header_64->cputype == CPU_TYPE_X86_64 ? @"CPU_TYPE_X86_64" :
                          mach_header_64->cputype == CPU_TYPE_ARM64 ? @"CPU_TYPE_ARM64" : @"???"];
  
  [dataController read_uint32:range lastReadHex:&lastReadHex];
  [node.details appendRow:[NSString stringWithFormat:@"%.8lX", range.location]
                         :lastReadHex
                         :@"CPU SubType"
                         :@""];

  if ((mach_header_64->cpusubtype & CPU_SUBTYPE_LIB64) == CPU_SUBTYPE_LIB64) [node.details appendRow:@"":@"":@"80000000":@"CPU_SUBTYPE_LIB64"];

  if (mach_header_64->cputype == CPU_TYPE_X86_64)
  {
    if ((mach_header_64->cpusubtype & ~CPU_SUBTYPE_MASK) == CPU_SUBTYPE_X86_64_ALL) [node.details appendRow:@"":@"":@"00000003":@"CPU_SUBTYPE_X86_64_ALL"]; 
  }
  else if (mach_header_64->cputype == CPU_TYPE_ARM64)
  {
    if ((mach_header_64->cpusubtype & ~CPU_SUBTYPE_MASK) == CPU_SUBTYPE_ARM64_ALL)  [node.details appendRow:@"":@"":@"00000000":@"CPU_SUBTYPE_ARM64_ALL"];
    if ((mach_header_64->cpusubtype & ~CPU_SUBTYPE_MASK) == CPU_SUBTYPE_ARM64_V8)   [node.details appendRow:@"":@"":@"00000001":@"CPU_SUBTYPE_ARM64_V8"];
  }

  
  [dataController read_uint32:range lastReadHex:&lastReadHex];
  [node.details appendRow:[NSString stringWithFormat:@"%.8lX", range.location]
                         :lastReadHex
                         :@"File Type"
                         :mach_header_64->filetype == MH_OBJECT ? @"MH_OBJECT" :
                          mach_header_64->filetype == MH_EXECUTE ? @"MH_EXECUTE" :
                          mach_header_64->filetype == MH_FVMLIB ? @"MH_FVMLIB" :
                          mach_header_64->filetype == MH_CORE ? @"MH_CORE" :
                          mach_header_64->filetype == MH_PRELOAD ? @"MH_PRELOAD" :
                          mach_header_64->filetype == MH_DYLIB ? @"MH_DYLIB" :
                          mach_header_64->filetype == MH_DYLINKER ? @"MH_DYLINKER" :
                          mach_header_64->filetype == MH_BUNDLE ? @"MH_BUNDLE" :
                          mach_header_64->filetype == MH_DYLIB_STUB ? @"MH_DYLIB_STUB" :
                          mach_header_64->filetype == MH_DSYM ? @"MH_DSYM" : 
                          mach_header_64->filetype == MH_KEXT_BUNDLE ? @"MH_KEXT_BUNDLE" : @"???"];
  
  [dataController read_uint32:range lastReadHex:&lastReadHex];
  [node.details appendRow:[NSString stringWithFormat:@"%.8lX", range.location]
                         :lastReadHex
                         :@"Number of Load Commands"
                         :[NSString stringWithFormat:@"%u", mach_header_64->ncmds]];
  
  [dataController read_uint32:range lastReadHex:&lastReadHex];
  [node.details appendRow:[NSString stringWithFormat:@"%.8lX", range.location]
                         :lastReadHex
                         :@"Size of Load Commands"
                         :[NSString stringWithFormat:@"%u", mach_header_64->sizeofcmds]];
  
  [dataController read_uint32:range lastReadHex:&lastReadHex];
  [node.details appendRow:[NSString stringWithFormat:@"%.8lX", range.location]
                         :lastReadHex
                         :@"Flags"
                         :@""];
  
  if (mach_header_64->flags & MH_NOUNDEFS)               [node.details appendRow:@"":@"":@"00000001":@"MH_NOUNDEFS"];
  if (mach_header_64->flags & MH_INCRLINK)               [node.details appendRow:@"":@"":@"00000002":@"MH_INCRLINK"];
  if (mach_header_64->flags & MH_DYLDLINK)               [node.details appendRow:@"":@"":@"00000004":@"MH_DYLDLINK"];
  if (mach_header_64->flags & MH_BINDATLOAD)             [node.details appendRow:@"":@"":@"00000008":@"MH_BINDATLOAD"];
  if (mach_header_64->flags & MH_PREBOUND)               [node.details appendRow:@"":@"":@"00000010":@"MH_PREBOUND"];
  if (mach_header_64->flags & MH_SPLIT_SEGS)             [node.details appendRow:@"":@"":@"00000020":@"MH_SPLIT_SEGS"];
  if (mach_header_64->flags & MH_LAZY_INIT)              [node.details appendRow:@"":@"":@"00000040":@"MH_LAZY_INIT"];
  if (mach_header_64->flags & MH_TWOLEVEL)               [node.details appendRow:@"":@"":@"00000080":@"MH_TWOLEVEL"];
  if (mach_header_64->flags & MH_FORCE_FLAT)             [node.details appendRow:@"":@"":@"00000100":@"MH_FORCE_FLAT"];
  if (mach_header_64->flags & MH_NOMULTIDEFS)            [node.details appendRow:@"":@"":@"00000200":@"MH_NOMULTIDEFS"];
  if (mach_header_64->flags & MH_NOFIXPREBINDING)        [node.details appendRow:@"":@"":@"00000400":@"MH_NOFIXPREBINDING"];
  if (mach_header_64->flags & MH_PREBINDABLE)            [node.details appendRow:@"":@"":@"00000800":@"MH_PREBINDABLE"];
  if (mach_header_64->flags & MH_ALLMODSBOUND)           [node.details appendRow:@"":@"":@"00001000":@"MH_ALLMODSBOUND"];
  if (mach_header_64->flags & MH_SUBSECTIONS_VIA_SYMBOLS)[node.details appendRow:@"":@"":@"00002000":@"MH_SUBSECTIONS_VIA_SYMBOLS"];
  if (mach_header_64->flags & MH_CANONICAL)              [node.details appendRow:@"":@"":@"00004000":@"MH_CANONICAL"];
  if (mach_header_64->flags & MH_WEAK_DEFINES)           [node.details appendRow:@"":@"":@"00008000":@"MH_WEAK_DEFINES"];
  if (mach_header_64->flags & MH_BINDS_TO_WEAK)          [node.details appendRow:@"":@"":@"00010000":@"MH_BINDS_TO_WEAK"];
  if (mach_header_64->flags & MH_ALLOW_STACK_EXECUTION)  [node.details appendRow:@"":@"":@"00020000":@"MH_ALLOW_STACK_EXECUTION"];
  if (mach_header_64->flags & MH_ROOT_SAFE)              [node.details appendRow:@"":@"":@"00040000":@"MH_ROOT_SAFE"];
  if (mach_header_64->flags & MH_SETUID_SAFE)            [node.details appendRow:@"":@"":@"00080000":@"MH_SETUID_SAFE"];
  if (mach_header_64->flags & MH_NO_REEXPORTED_DYLIBS)   [node.details appendRow:@"":@"":@"00100000":@"MH_NO_REEXPORTED_DYLIBS"];
  if (mach_header_64->flags & MH_PIE)                    [node.details appendRow:@"":@"":@"00200000":@"MH_PIE"];
  if (mach_header_64->flags & MH_DEAD_STRIPPABLE_DYLIB)  [node.details appendRow:@"":@"":@"00400000":@"MH_DEAD_STRIPPABLE_DYLIB"];
  if (mach_header_64->flags & MH_HAS_TLV_DESCRIPTORS)    [node.details appendRow:@"":@"":@"00800000":@"MH_HAS_TLV_DESCRIPTORS"];
  if (mach_header_64->flags & MH_NO_HEAP_EXECUTION)      [node.details appendRow:@"":@"":@"01000000":@"MH_NO_HEAP_EXECUTION"];                                  
  
  uint32_t reserved = [dataController read_uint32:range lastReadHex:&lastReadHex];
  [node.details appendRow:[NSString stringWithFormat:@"%.8lX", range.location]
                         :lastReadHex
                         :@"Reserved"
                         :[NSString stringWithFormat:@"%u", reserved]];
  return node;
}

//-----------------------------------------------------------------------------
- (void)doMainTasks
{
  uint32_t      ncmds;        // number of load commands
  uint32_t      sizeofcmds;   // the size of all the load commands
  
  // zero section (used to indicate absolute section relocations)
  sections.push_back(NULL); 
  sections_64.push_back(NULL); 
  
  // zero dylib (self)
  dylibs.push_back((struct dylib *)NULL);
  
  NSString * lastNodeCaption; // for error message
  
  // ============== Mach Header ===========
  if ([self is64bit] == NO)
  {
    MATCH_STRUCT(mach_header,imageOffset)
    ncmds = mach_header->ncmds;
    sizeofcmds = mach_header->sizeofcmds;

    @try
    {
      [self createMachONode:rootNode
                    caption:(lastNodeCaption = @"Mach Header")
                   location:imageOffset
                mach_header:mach_header];
    }
    @catch(NSException * exception)
    {
      [self printException:exception caption:lastNodeCaption];
    }
  }
  else //64bit
  {
    MATCH_STRUCT(mach_header_64,imageOffset)
    ncmds = mach_header_64->ncmds;
    sizeofcmds = mach_header_64->sizeofcmds;

    @try
    {
      [self createMachO64Node:rootNode
                      caption:(lastNodeCaption = @"Mach64 Header")
                     location:imageOffset
               mach_header_64:mach_header_64];
    }
    @catch(NSException * exception)
    {
      [self printException:exception caption:lastNodeCaption];
    }
  }
  
  
  //=========== Load Commands =============
  {
    uint32_t fileOffset = imageOffset + ([self is64bit] == NO 
                                         ? sizeof(struct mach_header) 
                                         : sizeof(struct mach_header_64));
    
    MVNode * commandsNode = [self createDataNode:rootNode 
                                         caption:@"Load Commands"
                                        location:fileOffset
                                          length:sizeofcmds];
    
    for (uint32_t ncmd = 0; ncmd < ncmds; ++ncmd)
    {
      MATCH_STRUCT(load_command,fileOffset)
      
      // store the command for post-processing
      commands.push_back(load_command);
      
      @try
      {
        [self createLoadCommandNode:commandsNode
                            caption:(lastNodeCaption = [self getNameForCommand:load_command->cmd])
                           location:fileOffset
                             length:load_command->cmdsize
                            command:load_command->cmd];
      }
      @catch(NSException * exception)
      {
        [self printException:exception caption:lastNodeCaption];
      }
      
      fileOffset += load_command->cmdsize;
    }
  }
  
  
  //=========================== Sections =========================
  NSRange relocsRange = NSMakeRange(0,0);
  
  if ([self is64bit] == NO)
  {
    for (SectionVector::const_iterator sectIter = ++sections.begin(); sectIter != sections.end(); ++sectIter)
    {
      struct section const * section = *sectIter;
      if (section->offset == 0)
      {
        continue;
      }
      
      MVNode * sectionNode = [self createDataNode:rootNode 
                                          caption:[NSString stringWithFormat:@"Section (%s,%s)", 
                                                   string(section->segname,16).c_str(),
                                                   string(section->sectname,16).c_str()]
                                         location:section->offset + imageOffset
                                           length:(section->flags & SECTION_TYPE) == S_ZEROFILL ||
                                                  (section->flags & SECTION_TYPE) == S_GB_ZEROFILL ? 0 : section->size];
      
      [sectionNode.userInfo addEntriesFromDictionary:[self userInfoForSection:section]];
      
      NSRange range = NSMakeRange(section->reloff + imageOffset, section->nreloc * sizeof(struct relocation_info));
      if (range.length > 0)
      {
        relocsRange = NSMaxRange(relocsRange) > 0 ? NSUnionRange(relocsRange,range) : range;
      }
    }
  }
  else //64bit
  {
    for (Section64Vector::const_iterator sectIter = ++sections_64.begin(); sectIter != sections_64.end(); ++sectIter)
    {
      struct section_64 const * section_64 = *sectIter;
      if (section_64->offset == 0)
      {
        continue;
      }
      
      MVNode * sectionNode = [self createDataNode:rootNode 
                                          caption:[NSString stringWithFormat:@"Section64 (%s,%s)", 
                                                   string(section_64->segname,16).c_str(),
                                                   string(section_64->sectname,16).c_str()]
                                         location:section_64->offset + imageOffset
                                           length:(section_64->flags & SECTION_TYPE) == S_ZEROFILL ||
                                                  (section_64->flags & SECTION_TYPE) == S_GB_ZEROFILL ? 0 : section_64->size];
      
      [sectionNode.userInfo addEntriesFromDictionary:[self userInfoForSection64:section_64]];
      
      NSRange range = NSMakeRange(section_64->reloff + imageOffset, section_64->nreloc * sizeof(struct relocation_info));
      if (range.length > 0)
      {
        relocsRange = NSMaxRange(relocsRange) > 0 ? NSUnionRange(relocsRange,range) : range;
      }
    }
  }
  
  
  //======================== Relocations ============================
  if (NSMaxRange(relocsRange) > 0)
  {
    MVNode * relocsNode = [self createDataNode:rootNode
                                       caption:@"Relocations"
                                      location:relocsRange.location
                                        length:relocsRange.length];
    
    [relocsNode.userInfo addEntriesFromDictionary:[self userInfoForRelocs]];
  }
 
  //======================== determine SDK ============================
  @try 
  {
    [self determineRuntimeVersion];
  }
  @catch(NSException * exception)
  {
    [self printException:exception caption:rootNode.caption];
  }
  
  [super doMainTasks];
}

//-----------------------------------------------------------------------------
- (void)doBackgroundTasks
{
  NSBlockOperation * linkEditOperation = [NSBlockOperation blockOperationWithBlock:^
  {
    if ([backgroundThread isCancelled]) return;
    @autoreleasepool {
      if ([self is64bit] == NO) [self processLinkEdit]; else [self processLinkEdit64];
    }
    NSLog(@"%@: LinkEdit finished parsing. (%lu symbols found)", self, 
    [self is64bit] == NO ? symbols.size() : symbols_64.size());
  }];
  
  NSBlockOperation * sectionRelocsOperation = [NSBlockOperation blockOperationWithBlock:^
  {
    if ([backgroundThread isCancelled]) return;
    @autoreleasepool {
      if ([self is64bit] == NO) [self processSectionRelocs]; else [self processSectionRelocs64];
    }
    NSLog(@"%@: Section relocations finished parsing.", self);
  }];
  
  NSBlockOperation * dyldInfoOperation = [NSBlockOperation blockOperationWithBlock:^
  {
    if ([backgroundThread isCancelled]) return;
    @autoreleasepool {
      [self processDyldInfo];
    }
    NSLog(@"%@: Dyld info finished parsing.", self);
  }];
  
  NSBlockOperation * sectionOperation = [NSBlockOperation blockOperationWithBlock:^
  {
    if ([backgroundThread isCancelled]) return;
    @autoreleasepool {
      if ([self is64bit] == NO) [self processSections]; else [self processSections64];
    }
    NSLog(@"%@: Section contents finished parsing.", self);
  }];
  
  NSBlockOperation * EHFramesOperation = [NSBlockOperation blockOperationWithBlock:^
  {
    if ([backgroundThread isCancelled]) return;
    @autoreleasepool {
      if ([self is64bit] == NO) [self processEHFrames]; else [self processEHFrames64];
    }
    NSLog(@"%@: Exception Frames finished parsing.", self);
  }];
  
  NSBlockOperation * LSDAsOperation = [NSBlockOperation blockOperationWithBlock:^
  {
    if ([backgroundThread isCancelled]) return;
    @autoreleasepool {
      if ([self is64bit] == NO) [self processLSDA]; else [self processLSDA64];
    }
    NSLog(@"%@: Lang Spec Data Areas finished parsing. (%lu LSDAs found)", self, lsdaInfo.size());
  }];
  
  NSBlockOperation * objcSectionOperation = [NSBlockOperation blockOperationWithBlock:^
  {
    if ([backgroundThread isCancelled]) return;
    @autoreleasepool {
      if ([self is64bit] == NO) [self processObjcSections]; else [self processObjcSections64];
    }
    NSLog(@"%@: ObjC Section contents finished parsing.", self);
  }];
  
  NSBlockOperation * codeSectionsOperation = [NSBlockOperation blockOperationWithBlock:^
  {
    if ([backgroundThread isCancelled]) return;
    @autoreleasepool {
      if ([self is64bit] == NO) [self processCodeSections]; else [self processCodeSections64];
    }
    NSLog(@"%@: Code sections finished parsing.", self);
  }];
  
  // setup dependencies
  [sectionOperation       addDependency:linkEditOperation];
  [sectionRelocsOperation addDependency:sectionOperation];
  [dyldInfoOperation      addDependency:sectionRelocsOperation];
  [objcSectionOperation   addDependency:dyldInfoOperation];
  [codeSectionsOperation  addDependency:objcSectionOperation];
  [EHFramesOperation      addDependency:dyldInfoOperation];
  [LSDAsOperation         addDependency:EHFramesOperation];
    
  // setup priorities
  [codeSectionsOperation  setQueuePriority:NSOperationQueuePriorityVeryLow];
  [codeSectionsOperation  setThreadPriority:0.0]; // this one will take the longest
  
  // start operations
  NSOperationQueue * oq = [[NSOperationQueue alloc] init];

  [dataController updateStatus:MVStatusTaskStarted];
  
  [oq   addOperations:[NSArray arrayWithObjects:linkEditOperation,
                                                sectionOperation,
                                                sectionRelocsOperation,
                                                dyldInfoOperation,
                                                EHFramesOperation,
                                                LSDAsOperation,
                                                objcSectionOperation,
                                                codeSectionsOperation,nil] 
    waitUntilFinished:YES];
  
  [super doBackgroundTasks];
  
  [dataController updateStatus:MVStatusTaskTerminated];
}

@end
