/*
 *  LoadCommands.mm
 *  MachOView
 *
 *  Created by psaghelyi on 20/07/2010.
 *
 */

#include <string>
#include <vector>
#include <set>
#include <map>

#import "Common.h"
#import "LoadCommands.h"
#import "ReadWrite.h"
#import "DataController.h"

using namespace std;

//============================================================================
@implementation MachOLayout (LoadCommands)

//-----------------------------------------------------------------------------
- (NSString *)getNameForCommand:(uint32_t)cmd
{
  switch(cmd)
  {
    default:                      return @"???";
    case LC_SEGMENT:              return @"LC_SEGMENT";             
    case LC_SYMTAB:               return @"LC_SYMTAB";               
    case LC_SYMSEG:               return @"LC_SYMSEG";              
    case LC_THREAD:               return @"LC_THREAD";              
    case LC_UNIXTHREAD:           return @"LC_UNIXTHREAD";          
    case LC_LOADFVMLIB:           return @"LC_LOADFVMLIB";          
    case LC_IDFVMLIB:             return @"LC_IDFVMLIB";            
    case LC_IDENT:                return @"LC_IDENT";               
    case LC_FVMFILE:              return @"LC_FVMFILE";             
    case LC_PREPAGE:              return @"LC_PREPAGE";             
    case LC_DYSYMTAB:             return @"LC_DYSYMTAB";            
    case LC_LOAD_DYLIB:           return @"LC_LOAD_DYLIB";          
    case LC_ID_DYLIB:             return @"LC_ID_DYLIB";            
    case LC_LOAD_DYLINKER:        return @"LC_LOAD_DYLINKER";       
    case LC_ID_DYLINKER:          return @"LC_ID_DYLINKER";         
    case LC_PREBOUND_DYLIB:       return @"LC_PREBOUND_DYLIB";      
    case LC_ROUTINES:             return @"LC_ROUTINES";            
    case LC_SUB_FRAMEWORK:        return @"LC_SUB_FRAMEWORK";       
    case LC_SUB_UMBRELLA:         return @"LC_SUB_UMBRELLA";        
    case LC_SUB_CLIENT:           return @"LC_SUB_CLIENT";          
    case LC_SUB_LIBRARY:          return @"LC_SUB_LIBRARY";         
    case LC_TWOLEVEL_HINTS:       return @"LC_TWOLEVEL_HINTS";      
    case LC_PREBIND_CKSUM:        return @"LC_PREBIND_CKSUM";       
    case LC_LOAD_WEAK_DYLIB:      return @"LC_LOAD_WEAK_DYLIB";     
    case LC_SEGMENT_64:           return @"LC_SEGMENT_64";          
    case LC_ROUTINES_64:          return @"LC_ROUTINES_64";         
    case LC_UUID:                 return @"LC_UUID";                
    case LC_RPATH:                return @"LC_RPATH";               
    case LC_CODE_SIGNATURE:       return @"LC_CODE_SIGNATURE";      
    case LC_SEGMENT_SPLIT_INFO:   return @"LC_SEGMENT_SPLIT_INFO";  
    case LC_REEXPORT_DYLIB:       return @"LC_REEXPORT_DYLIB";      
    case LC_LAZY_LOAD_DYLIB:      return @"LC_LAZY_LOAD_DYLIB";     
    case LC_ENCRYPTION_INFO:      return @"LC_ENCRYPTION_INFO";     
    case LC_ENCRYPTION_INFO_64:   return @"LC_ENCRYPTION_INFO_64";
    case LC_DYLD_INFO:            return @"LC_DYLD_INFO";           
    case LC_DYLD_INFO_ONLY:       return @"LC_DYLD_INFO_ONLY";      
    case LC_LOAD_UPWARD_DYLIB:    return @"LC_LOAD_UPWARD_DYLIB";
    case LC_VERSION_MIN_MACOSX:   return @"LC_VERSION_MIN_MACOSX";
    case LC_VERSION_MIN_IPHONEOS: return @"LC_VERSION_MIN_IPHONEOS";
    case LC_FUNCTION_STARTS:      return @"LC_FUNCTION_STARTS";
    case LC_DYLD_ENVIRONMENT:     return @"LC_DYLD_ENVIRONMENT";
    case LC_MAIN:                 return @"LC_MAIN";
    case LC_DATA_IN_CODE:         return @"LC_DATA_IN_CODE";
    case LC_SOURCE_VERSION:       return @"LC_SOURCE_VERSION";
    case LC_DYLIB_CODE_SIGN_DRS:  return @"LC_DYLIB_CODE_SIGN_DRS";
    case LC_LINKER_OPTION:        return @"LC_LINKER_OPTION";
    case LC_LINKER_OPTIMIZATION_HINT: return @"LC_LINKER_OPTIMIZATION_HINT";
  }
}

//-----------------------------------------------------------------------------
- (MVNode *)createLCSegmentNode:(MVNode *)parent
                      caption:(NSString *)caption
                     location:(uint32_t)location
              segment_command:(struct segment_command const *)segment_command
{
  MVNodeSaver nodeSaver;
  MVNode * node = [parent insertChildWithDetails:caption location:location length:segment_command->cmdsize saver:nodeSaver]; 
  
  NSRange range = NSMakeRange(location,0);
  NSString * lastReadHex;
  
  [dataController read_uint32:range lastReadHex:&lastReadHex];
  [node.details appendRow:[NSString stringWithFormat:@"%.8lX", range.location]
                         :lastReadHex
                         :@"Command"
                         :[self getNameForCommand:segment_command->cmd]];

  [node.details setAttributes:MVCellColorAttributeName,[NSColor greenColor],nil];
  
  [dataController read_uint32:range lastReadHex:&lastReadHex];
  [node.details appendRow:[NSString stringWithFormat:@"%.8lX", range.location]
                         :lastReadHex
                         :@"Command Size"
                         :[NSString stringWithFormat:@"%u", segment_command->cmdsize]];
  
  [node.details setAttributes:MVCellColorAttributeName,[NSColor greenColor],
                              MVUnderlineAttributeName,@"YES",nil];
  
  [dataController read_string:range fixlen:16 lastReadHex:&lastReadHex];
  [node.details appendRow:[NSString stringWithFormat:@"%.8lX", range.location]
                         :lastReadHex
                         :@"Segment Name"
                         :[NSString stringWithFormat:@"%s", string(segment_command->segname,16).c_str()]];
  
  [dataController read_uint32:range lastReadHex:&lastReadHex];
  [node.details appendRow:[NSString stringWithFormat:@"%.8lX", range.location]
                         :lastReadHex
                         :@"VM Address"
                         :[NSString stringWithFormat:@"0x%X", segment_command->vmaddr]];
  
  [dataController read_uint32:range lastReadHex:&lastReadHex];
  [node.details appendRow:[NSString stringWithFormat:@"%.8lX", range.location]
                         :lastReadHex
                         :@"VM Size"
                         :[NSString stringWithFormat:@"%u", segment_command->vmsize]];
  
  [dataController read_uint32:range lastReadHex:&lastReadHex];
  [node.details appendRow:[NSString stringWithFormat:@"%.8lX", range.location]
                         :lastReadHex
                         :@"File Offset"
                         :[NSString stringWithFormat:@"%u", segment_command->fileoff]];
  
  [dataController read_uint32:range lastReadHex:&lastReadHex];
  [node.details appendRow:[NSString stringWithFormat:@"%.8lX", range.location]
                         :lastReadHex
                         :@"File Size"
                         :[NSString stringWithFormat:@"%u", segment_command->filesize]];
  
  [dataController read_uint32:range lastReadHex:&lastReadHex];
  [node.details appendRow:[NSString stringWithFormat:@"%.8lX", range.location]
                         :lastReadHex
                         :@"Maximum VM Protection"
                         :@""];
  
  if (segment_command->maxprot == VM_PROT_NONE)    [node.details appendRow:@"":@"":@"00000000":@"VM_PROT_NONE"];
  if (segment_command->maxprot & VM_PROT_READ)     [node.details appendRow:@"":@"":@"00000001":@"VM_PROT_READ"];
  if (segment_command->maxprot & VM_PROT_WRITE)    [node.details appendRow:@"":@"":@"00000002":@"VM_PROT_WRITE"];
  if (segment_command->maxprot & VM_PROT_EXECUTE)  [node.details appendRow:@"":@"":@"00000004":@"VM_PROT_EXECUTE"];
  
  [dataController read_uint32:range lastReadHex:&lastReadHex];
  [node.details appendRow:[NSString stringWithFormat:@"%.8lX", range.location]
                         :lastReadHex
                         :@"Initial VM Protection"
                         :@""];
  
  if (segment_command->initprot == VM_PROT_NONE)   [node.details appendRow:@"":@"":@"00000000":@"VM_PROT_NONE"];
  if (segment_command->initprot & VM_PROT_READ)    [node.details appendRow:@"":@"":@"00000001":@"VM_PROT_READ"];
  if (segment_command->initprot & VM_PROT_WRITE)   [node.details appendRow:@"":@"":@"00000002":@"VM_PROT_WRITE"];
  if (segment_command->initprot & VM_PROT_EXECUTE) [node.details appendRow:@"":@"":@"00000004":@"VM_PROT_EXECUTE"];
  
  [dataController read_uint32:range lastReadHex:&lastReadHex];
  [node.details appendRow:[NSString stringWithFormat:@"%.8lX", range.location]
                         :lastReadHex
                         :@"Number of Sections"
                         :[NSString stringWithFormat:@"%u", segment_command->nsects]];
  
  [dataController read_uint32:range lastReadHex:&lastReadHex];
  [node.details appendRow:[NSString stringWithFormat:@"%.8lX", range.location]
                         :lastReadHex
                         :@"Flags"
                         :@""];
  
  if (segment_command->flags & SG_HIGHVM)              [node.details appendRow:@"":@"":@"00000001":@"SG_HIGHVM"];
  if (segment_command->flags & SG_FVMLIB)              [node.details appendRow:@"":@"":@"00000002":@"SG_FVMLIB"];
  if (segment_command->flags & SG_NORELOC)             [node.details appendRow:@"":@"":@"00000004":@"SG_NORELOC"];
  if (segment_command->flags & SG_PROTECTED_VERSION_1) [node.details appendRow:@"":@"":@"00000008":@"SG_PROTECTED_VERSION_1"];
  
  return node;
}

//-----------------------------------------------------------------------------
- (MVNode *)createSectionNode:(MVNode *)parent
                    caption:(NSString *)caption
                   location:(uint32_t)location
                    section:(struct section const *)section
{
  MVNodeSaver nodeSaver;
  MVNode * node = [parent insertChildWithDetails:caption location:location length:sizeof(struct section) saver:nodeSaver]; 
  
  NSRange range = NSMakeRange(location,0);
  NSString * lastReadHex;
  
  [dataController read_string:range fixlen:16 lastReadHex:&lastReadHex];
  [node.details appendRow:[NSString stringWithFormat:@"%.8lX", range.location]
                         :lastReadHex
                         :@"Section Name"
                         :[NSString stringWithFormat:@"%s", string(section->sectname,16).c_str()]];
  
  [dataController read_string:range fixlen:16 lastReadHex:&lastReadHex];
  [node.details appendRow:[NSString stringWithFormat:@"%.8lX", range.location]
                         :lastReadHex
                         :@"Segment Name"
                         :[NSString stringWithFormat:@"%s", string(section->segname,16).c_str()]];

  [dataController read_uint32:range lastReadHex:&lastReadHex];
  [node.details appendRow:[NSString stringWithFormat:@"%.8lX", range.location]
                         :lastReadHex
                         :@"Address"
                         :[NSString stringWithFormat:@"0x%X", section->addr]];
  
  [dataController read_uint32:range lastReadHex:&lastReadHex];
  [node.details appendRow:[NSString stringWithFormat:@"%.8lX", range.location]
                         :lastReadHex
                         :@"Size"
                         :[NSString stringWithFormat:@"%u", section->size]];
  
  [dataController read_uint32:range lastReadHex:&lastReadHex];
  [node.details appendRow:[NSString stringWithFormat:@"%.8lX", range.location]
                         :lastReadHex
                         :@"Offset"
                         :[NSString stringWithFormat:@"%u", section->offset]];
  
  [dataController read_uint32:range lastReadHex:&lastReadHex];
  [node.details appendRow:[NSString stringWithFormat:@"%.8lX", range.location]
                         :lastReadHex
                         :@"Alignment"
                         :[NSString stringWithFormat:@"%u", (1 << section->align)]];
  
  [dataController read_uint32:range lastReadHex:&lastReadHex];
  [node.details appendRow:[NSString stringWithFormat:@"%.8lX", range.location]
                         :lastReadHex
                         :@"Relocations Offset"
                         :[NSString stringWithFormat:@"%u", section->reloff]];
  
  [dataController read_uint32:range lastReadHex:&lastReadHex];
  [node.details appendRow:[NSString stringWithFormat:@"%.8lX", range.location]
                         :lastReadHex
                         :@"Number of Relocations"
                         :[NSString stringWithFormat:@"%u", section->nreloc]];
  
  [dataController read_uint32:range lastReadHex:&lastReadHex];
  [node.details appendRow:[NSString stringWithFormat:@"%.8lX", range.location]
                         :lastReadHex
                         :@"Flags"
                         :@""];
  
  switch (section->flags & SECTION_TYPE)
  {
    case S_REGULAR:                             [node.details appendRow:@"":@"":@"00000000":@"S_REGULAR"]; break;
    case S_ZEROFILL:                            [node.details appendRow:@"":@"":@"00000001":@"S_ZEROFILL"]; break;
    case S_CSTRING_LITERALS:                    [node.details appendRow:@"":@"":@"00000002":@"S_CSTRING_LITERALS"]; break;
    case S_4BYTE_LITERALS:                      [node.details appendRow:@"":@"":@"00000003":@"S_4BYTE_LITERALS"]; break;
    case S_8BYTE_LITERALS:                      [node.details appendRow:@"":@"":@"00000004":@"S_8BYTE_LITERALS"]; break;
    case S_LITERAL_POINTERS:                    [node.details appendRow:@"":@"":@"00000005":@"S_LITERAL_POINTERS"]; break;
    case S_NON_LAZY_SYMBOL_POINTERS:            [node.details appendRow:@"":@"":@"00000006":@"S_NON_LAZY_SYMBOL_POINTERS"]; break;
    case S_LAZY_SYMBOL_POINTERS:                [node.details appendRow:@"":@"":@"00000007":@"S_LAZY_SYMBOL_POINTERS"]; break;
    case S_SYMBOL_STUBS:                        [node.details appendRow:@"":@"":@"00000008":@"S_SYMBOL_STUBS"]; break;
    case S_MOD_INIT_FUNC_POINTERS:              [node.details appendRow:@"":@"":@"00000009":@"S_MOD_INIT_FUNC_POINTERS"]; break;
    case S_MOD_TERM_FUNC_POINTERS:              [node.details appendRow:@"":@"":@"0000000A":@"S_MOD_TERM_FUNC_POINTERS"]; break;
    case S_COALESCED:                           [node.details appendRow:@"":@"":@"0000000B":@"S_COALESCED"]; break;
    case S_GB_ZEROFILL:                         [node.details appendRow:@"":@"":@"0000000C":@"S_GB_ZEROFILL"]; break;
    case S_INTERPOSING:                         [node.details appendRow:@"":@"":@"0000000D":@"S_INTERPOSING"]; break;
    case S_16BYTE_LITERALS:                     [node.details appendRow:@"":@"":@"0000000E":@"S_16BYTE_LITERALS"]; break;
    case S_DTRACE_DOF:                          [node.details appendRow:@"":@"":@"0000000F":@"S_DTRACE_DOF"]; break;
    case S_LAZY_DYLIB_SYMBOL_POINTERS:          [node.details appendRow:@"":@"":@"00000010":@"S_LAZY_DYLIB_SYMBOL_POINTERS"]; break;
    case S_THREAD_LOCAL_REGULAR:                [node.details appendRow:@"":@"":@"00000011":@"S_THREAD_LOCAL_REGULAR"]; break;
    case S_THREAD_LOCAL_ZEROFILL:               [node.details appendRow:@"":@"":@"00000012":@"S_THREAD_LOCAL_ZEROFILL"]; break;
    case S_THREAD_LOCAL_VARIABLES:              [node.details appendRow:@"":@"":@"00000013":@"S_THREAD_LOCAL_VARIABLES"]; break;
    case S_THREAD_LOCAL_VARIABLE_POINTERS:      [node.details appendRow:@"":@"":@"00000014":@"S_THREAD_LOCAL_VARIABLE_POINTERS"]; break;
    case S_THREAD_LOCAL_INIT_FUNCTION_POINTERS: [node.details appendRow:@"":@"":@"00000015":@"S_THREAD_LOCAL_INIT_FUNCTION_POINTERS"]; break;
  }
  
  if (section->flags & S_ATTR_PURE_INSTRUCTIONS)   [node.details appendRow:@"":@"":@"80000000":@"S_ATTR_PURE_INSTRUCTIONS"];
  if (section->flags & S_ATTR_NO_TOC)              [node.details appendRow:@"":@"":@"40000000":@"S_ATTR_NO_TOC"];
  if (section->flags & S_ATTR_STRIP_STATIC_SYMS)   [node.details appendRow:@"":@"":@"20000000":@"S_ATTR_STRIP_STATIC_SYMS"];
  if (section->flags & S_ATTR_NO_DEAD_STRIP)       [node.details appendRow:@"":@"":@"10000000":@"S_ATTR_NO_DEAD_STRIP"];
  if (section->flags & S_ATTR_LIVE_SUPPORT)        [node.details appendRow:@"":@"":@"08000000":@"S_ATTR_LIVE_SUPPORT"];
  if (section->flags & S_ATTR_SELF_MODIFYING_CODE) [node.details appendRow:@"":@"":@"04000000":@"S_ATTR_SELF_MODIFYING_CODE"];
  if (section->flags & S_ATTR_DEBUG)               [node.details appendRow:@"":@"":@"02000000":@"S_ATTR_DEBUG"];
  if (section->flags & S_ATTR_SOME_INSTRUCTIONS)   [node.details appendRow:@"":@"":@"00000400":@"S_ATTR_SOME_INSTRUCTIONS"];
  if (section->flags & S_ATTR_EXT_RELOC)           [node.details appendRow:@"":@"":@"00000200":@"S_ATTR_EXT_RELOC"];
  if (section->flags & S_ATTR_LOC_RELOC)           [node.details appendRow:@"":@"":@"00000100":@"S_ATTR_LOC_RELOC"];
  
  [dataController read_uint32:range lastReadHex:&lastReadHex];
  [node.details appendRow:[NSString stringWithFormat:@"%.8lX", range.location]
                         :lastReadHex
                         :(section->flags & SECTION_TYPE) == S_SYMBOL_STUBS ||
                          (section->flags & SECTION_TYPE) == S_LAZY_SYMBOL_POINTERS ||
                          (section->flags & SECTION_TYPE) == S_LAZY_DYLIB_SYMBOL_POINTERS ||
                          (section->flags & SECTION_TYPE) == S_NON_LAZY_SYMBOL_POINTERS ? @"Indirect Sym Index" : @"Reserved1"
                         :[NSString stringWithFormat:@"%u", section->reserved1]];

  [dataController read_uint32:range lastReadHex:&lastReadHex];
  [node.details appendRow:[NSString stringWithFormat:@"%.8lX", range.location]
                         :lastReadHex
                         :(section->flags & SECTION_TYPE) == S_SYMBOL_STUBS ? @"Size of Stubs" : @"Reserved2"
                         :[NSString stringWithFormat:@"%u", section->reserved2]];
  return node;
}

//-----------------------------------------------------------------------------
- (MVNode *)createLCSegment64Node:(MVNode *)parent
                        caption:(NSString *)caption
                       location:(uint32_t)location
             segment_command_64:(struct segment_command_64 const *)segment_command_64
{
  MVNodeSaver nodeSaver;
  MVNode * node = [parent insertChildWithDetails:caption location:location length:segment_command_64->cmdsize saver:nodeSaver];
  
  NSRange range = NSMakeRange(location,0);
  NSString * lastReadHex;
  
  [dataController read_uint32:range lastReadHex:&lastReadHex];
  [node.details appendRow:[NSString stringWithFormat:@"%.8lX", range.location]
                         :lastReadHex
                         :@"Command"
                         :[self getNameForCommand:segment_command_64->cmd]];

  [node.details setAttributes:MVCellColorAttributeName,[NSColor greenColor],nil];

  [dataController read_uint32:range lastReadHex:&lastReadHex];
  [node.details appendRow:[NSString stringWithFormat:@"%.8lX", range.location]
                         :lastReadHex
                         :@"Command Size"
                         :[NSString stringWithFormat:@"%u", segment_command_64->cmdsize]];

  [node.details setAttributes:MVCellColorAttributeName,[NSColor greenColor],
                              MVUnderlineAttributeName,@"YES",nil];
  
  [dataController read_string:range fixlen:16 lastReadHex:&lastReadHex];
  [node.details appendRow:[NSString stringWithFormat:@"%.8lX", range.location]
                         :lastReadHex
                         :@"Segment Name"
                         :[NSString stringWithFormat:@"%s", string(segment_command_64->segname,16).c_str()]];
  
  [dataController read_uint64:range lastReadHex:&lastReadHex];
  [node.details appendRow:[NSString stringWithFormat:@"%.8lX", range.location]
                         :lastReadHex
                         :@"VM Address"
                         :[NSString stringWithFormat:@"%qu", segment_command_64->vmaddr]];
  
  [dataController read_uint64:range lastReadHex:&lastReadHex];
  [node.details appendRow:[NSString stringWithFormat:@"%.8lX", range.location]
                         :lastReadHex
                         :@"VM Size"
                         :[NSString stringWithFormat:@"%qu", segment_command_64->vmsize]];
  
  [dataController read_uint64:range lastReadHex:&lastReadHex];
  [node.details appendRow:[NSString stringWithFormat:@"%.8lX", range.location]
                         :lastReadHex
                         :@"File Offset"
                         :[NSString stringWithFormat:@"%qu", segment_command_64->fileoff]];
  
  [dataController read_uint64:range lastReadHex:&lastReadHex];
  [node.details appendRow:[NSString stringWithFormat:@"%.8lX", range.location]
                         :lastReadHex
                         :@"File Size"
                         :[NSString stringWithFormat:@"%qu", segment_command_64->filesize]];
  
  [dataController read_uint32:range lastReadHex:&lastReadHex];
  [node.details appendRow:[NSString stringWithFormat:@"%.8lX", range.location]
                         :lastReadHex
                         :@"Maximum VM Protection"
                         :@""];
  
  if (segment_command_64->maxprot == VM_PROT_NONE)   [node.details appendRow:@"":@"":@"00000000":@"VM_PROT_NONE"];
  if (segment_command_64->maxprot & VM_PROT_READ)    [node.details appendRow:@"":@"":@"00000001":@"VM_PROT_READ"];
  if (segment_command_64->maxprot & VM_PROT_WRITE)   [node.details appendRow:@"":@"":@"00000002":@"VM_PROT_WRITE"];
  if (segment_command_64->maxprot & VM_PROT_EXECUTE) [node.details appendRow:@"":@"":@"00000004":@"VM_PROT_EXECUTE"];
  
  [dataController read_uint32:range lastReadHex:&lastReadHex];
  [node.details appendRow:[NSString stringWithFormat:@"%.8lX", range.location]
                         :lastReadHex
                         :@"Initial VM Protection"
                         :@""];
  
  if (segment_command_64->initprot == VM_PROT_NONE)  [node.details appendRow:@"":@"":@"00000000":@"VM_PROT_NONE"];
  if (segment_command_64->initprot & VM_PROT_READ)   [node.details appendRow:@"":@"":@"00000001":@"VM_PROT_READ"];
  if (segment_command_64->initprot & VM_PROT_WRITE)  [node.details appendRow:@"":@"":@"00000002":@"VM_PROT_WRITE"];
  if (segment_command_64->initprot & VM_PROT_EXECUTE)[node.details appendRow:@"":@"":@"00000004":@"VM_PROT_EXECUTE"];
  
  [dataController read_uint32:range lastReadHex:&lastReadHex];
  [node.details appendRow:[NSString stringWithFormat:@"%.8lX", range.location]
                         :lastReadHex
                         :@"Number of Sections"
                         :[NSString stringWithFormat:@"%u", segment_command_64->nsects]];
  
  [dataController read_uint32:range lastReadHex:&lastReadHex];
  [node.details appendRow:[NSString stringWithFormat:@"%.8lX", range.location]
                         :lastReadHex
                         :@"Flags"
                         :@""];
  
  if (segment_command_64->flags & SG_HIGHVM)              [node.details appendRow:@"":@"":@"00000001":@"SG_HIGHVM"];
  if (segment_command_64->flags & SG_FVMLIB)              [node.details appendRow:@"":@"":@"00000002":@"SG_FVMLIB"];
  if (segment_command_64->flags & SG_NORELOC)             [node.details appendRow:@"":@"":@"00000004":@"SG_NORELOC"];
  if (segment_command_64->flags & SG_PROTECTED_VERSION_1) [node.details appendRow:@"":@"":@"00000008":@"SG_PROTECTED_VERSION_1"];
  
  return node;
}

//-----------------------------------------------------------------------------
- (MVNode *)createSection64Node:(MVNode *)parent
                    caption:(NSString *)caption
                   location:(uint32_t)location
                 section_64:(struct section_64 const *)section_64
{
  MVNodeSaver nodeSaver;
  MVNode * node = [parent insertChildWithDetails:caption location:location length:sizeof(struct section_64) saver:nodeSaver]; 
  
  NSRange range = NSMakeRange(location,0);
  NSString * lastReadHex;
  
  [dataController read_string:range fixlen:16 lastReadHex:&lastReadHex];
  [node.details appendRow:[NSString stringWithFormat:@"%.8lX", range.location]
                         :lastReadHex
                         :@"Section Name"
                         :[NSString stringWithFormat:@"%s", string(section_64->sectname,16).c_str()]];
  
  [dataController read_string:range fixlen:16 lastReadHex:&lastReadHex];
  [node.details appendRow:[NSString stringWithFormat:@"%.8lX", range.location]
                         :lastReadHex
                         :@"Segment Name"
                         :[NSString stringWithFormat:@"%s", string(section_64->segname,16).c_str()]];
  
  [dataController read_uint64:range lastReadHex:&lastReadHex];
  [node.details appendRow:[NSString stringWithFormat:@"%.8lX", range.location]
                         :lastReadHex
                         :@"Address"
                         :[NSString stringWithFormat:@"%qu", section_64->addr]];
  
  [dataController read_uint64:range lastReadHex:&lastReadHex];
  [node.details appendRow:[NSString stringWithFormat:@"%.8lX", range.location]
                         :lastReadHex
                         :@"Size"
                         :[NSString stringWithFormat:@"%qu", section_64->size]];
  
  [dataController read_uint32:range lastReadHex:&lastReadHex];
  [node.details appendRow:[NSString stringWithFormat:@"%.8lX", range.location]
                         :lastReadHex
                         :@"Offset"
                         :[NSString stringWithFormat:@"%u", section_64->offset]];
  
  [dataController read_uint32:range lastReadHex:&lastReadHex];
  [node.details appendRow:[NSString stringWithFormat:@"%.8lX", range.location]
                         :lastReadHex
                         :@"Alignment"
                         :[NSString stringWithFormat:@"%u", (1 << section_64->align)]];
  
  [dataController read_uint32:range lastReadHex:&lastReadHex];
  [node.details appendRow:[NSString stringWithFormat:@"%.8lX", range.location]
                         :lastReadHex
                         :@"Relocations Offset"
                         :[NSString stringWithFormat:@"%u", section_64->reloff]];
  
  [dataController read_uint32:range lastReadHex:&lastReadHex];
  [node.details appendRow:[NSString stringWithFormat:@"%.8lX", range.location]
                         :lastReadHex
                         :@"Number of Relocations"
                         :[NSString stringWithFormat:@"%u", section_64->nreloc]];
  
  [dataController read_uint32:range lastReadHex:&lastReadHex];
  [node.details appendRow:[NSString stringWithFormat:@"%.8lX", range.location]
                         :lastReadHex
                         :@"Flags"
                         :@""];
  
  switch (section_64->flags & SECTION_TYPE)
  {
    case S_REGULAR:                             [node.details appendRow:@"":@"":@"00000000":@"S_REGULAR"]; break;
    case S_ZEROFILL:                            [node.details appendRow:@"":@"":@"00000001":@"S_ZEROFILL"]; break;
    case S_CSTRING_LITERALS:                    [node.details appendRow:@"":@"":@"00000002":@"S_CSTRING_LITERALS"]; break;
    case S_4BYTE_LITERALS:                      [node.details appendRow:@"":@"":@"00000003":@"S_4BYTE_LITERALS"]; break;
    case S_8BYTE_LITERALS:                      [node.details appendRow:@"":@"":@"00000004":@"S_8BYTE_LITERALS"]; break;
    case S_LITERAL_POINTERS:                    [node.details appendRow:@"":@"":@"00000005":@"S_LITERAL_POINTERS"]; break;
    case S_NON_LAZY_SYMBOL_POINTERS:            [node.details appendRow:@"":@"":@"00000006":@"S_NON_LAZY_SYMBOL_POINTERS"]; break;
    case S_LAZY_SYMBOL_POINTERS:                [node.details appendRow:@"":@"":@"00000007":@"S_LAZY_SYMBOL_POINTERS"]; break;
    case S_SYMBOL_STUBS:                        [node.details appendRow:@"":@"":@"00000008":@"S_SYMBOL_STUBS"]; break;
    case S_MOD_INIT_FUNC_POINTERS:              [node.details appendRow:@"":@"":@"00000009":@"S_MOD_INIT_FUNC_POINTERS"]; break;
    case S_MOD_TERM_FUNC_POINTERS:              [node.details appendRow:@"":@"":@"0000000A":@"S_MOD_TERM_FUNC_POINTERS"]; break;
    case S_COALESCED:                           [node.details appendRow:@"":@"":@"0000000B":@"S_COALESCED"]; break;
    case S_GB_ZEROFILL:                         [node.details appendRow:@"":@"":@"0000000C":@"S_GB_ZEROFILL"]; break;
    case S_INTERPOSING:                         [node.details appendRow:@"":@"":@"0000000D":@"S_INTERPOSING"]; break;
    case S_16BYTE_LITERALS:                     [node.details appendRow:@"":@"":@"0000000E":@"S_16BYTE_LITERALS"]; break;
    case S_DTRACE_DOF:                          [node.details appendRow:@"":@"":@"0000000F":@"S_DTRACE_DOF"]; break;
    case S_LAZY_DYLIB_SYMBOL_POINTERS:          [node.details appendRow:@"":@"":@"00000010":@"S_LAZY_DYLIB_SYMBOL_POINTERS"]; break;
    case S_THREAD_LOCAL_REGULAR:                [node.details appendRow:@"":@"":@"00000011":@"S_THREAD_LOCAL_REGULAR"]; break;
    case S_THREAD_LOCAL_ZEROFILL:               [node.details appendRow:@"":@"":@"00000012":@"S_THREAD_LOCAL_ZEROFILL"]; break;
    case S_THREAD_LOCAL_VARIABLES:              [node.details appendRow:@"":@"":@"00000013":@"S_THREAD_LOCAL_VARIABLES"]; break;
    case S_THREAD_LOCAL_VARIABLE_POINTERS:      [node.details appendRow:@"":@"":@"00000014":@"S_THREAD_LOCAL_VARIABLE_POINTERS"]; break;
    case S_THREAD_LOCAL_INIT_FUNCTION_POINTERS: [node.details appendRow:@"":@"":@"00000015":@"S_THREAD_LOCAL_INIT_FUNCTION_POINTERS"]; break;
  }
  
  if (section_64->flags & S_ATTR_PURE_INSTRUCTIONS)   [node.details appendRow:@"":@"":@"80000000":@"S_ATTR_PURE_INSTRUCTIONS"];
  if (section_64->flags & S_ATTR_NO_TOC)              [node.details appendRow:@"":@"":@"40000000":@"S_ATTR_NO_TOC"];
  if (section_64->flags & S_ATTR_STRIP_STATIC_SYMS)   [node.details appendRow:@"":@"":@"20000000":@"S_ATTR_STRIP_STATIC_SYMS"];
  if (section_64->flags & S_ATTR_NO_DEAD_STRIP)       [node.details appendRow:@"":@"":@"10000000":@"S_ATTR_NO_DEAD_STRIP"];
  if (section_64->flags & S_ATTR_LIVE_SUPPORT)        [node.details appendRow:@"":@"":@"08000000":@"S_ATTR_LIVE_SUPPORT"];
  if (section_64->flags & S_ATTR_SELF_MODIFYING_CODE) [node.details appendRow:@"":@"":@"04000000":@"S_ATTR_SELF_MODIFYING_CODE"];
  if (section_64->flags & S_ATTR_DEBUG)               [node.details appendRow:@"":@"":@"02000000":@"S_ATTR_DEBUG"];
  if (section_64->flags & S_ATTR_SOME_INSTRUCTIONS)   [node.details appendRow:@"":@"":@"00000400":@"S_ATTR_SOME_INSTRUCTIONS"];
  if (section_64->flags & S_ATTR_EXT_RELOC)           [node.details appendRow:@"":@"":@"00000200":@"S_ATTR_EXT_RELOC"];
  if (section_64->flags & S_ATTR_LOC_RELOC)           [node.details appendRow:@"":@"":@"00000100":@"S_ATTR_LOC_RELOC"];
  
  [dataController read_uint32:range lastReadHex:&lastReadHex];
  [node.details appendRow:[NSString stringWithFormat:@"%.8lX", range.location]
                         :lastReadHex
                         :(section_64->flags & SECTION_TYPE) == S_SYMBOL_STUBS ||
                          (section_64->flags & SECTION_TYPE) == S_LAZY_SYMBOL_POINTERS ||
                          (section_64->flags & SECTION_TYPE) == S_LAZY_DYLIB_SYMBOL_POINTERS ||
                          (section_64->flags & SECTION_TYPE) == S_NON_LAZY_SYMBOL_POINTERS ? @"Indirect Sym Index" : @"Reserved1"
                         :[NSString stringWithFormat:@"%u", section_64->reserved1]];
  
  [dataController read_uint32:range lastReadHex:&lastReadHex];
  [node.details appendRow:[NSString stringWithFormat:@"%.8lX", range.location]
                         :lastReadHex
                         :(section_64->flags & SECTION_TYPE) == S_SYMBOL_STUBS ? @"Size of Stubs" : @"Reserved2"
                         :[NSString stringWithFormat:@"%u", section_64->reserved2]];

  [dataController read_uint32:range lastReadHex:&lastReadHex];
  [node.details appendRow:[NSString stringWithFormat:@"%.8lX", range.location]
                         :lastReadHex
                         :@"Reserved3"
                         :[NSString stringWithFormat:@"%u", section_64->reserved3]];
  return node;
}

//-----------------------------------------------------------------------------
- (MVNode *)createLCSymtabNode:(MVNode *)parent
                     caption:(NSString *)caption
                    location:(uint32_t)location
              symtab_command:(struct symtab_command const *)symtab_command
{
  MVNodeSaver nodeSaver;
  MVNode * node = [parent insertChildWithDetails:caption location:location length:symtab_command->cmdsize saver:nodeSaver]; 
  
  NSRange range = NSMakeRange(location,0);
  NSString * lastReadHex;
  
  [dataController read_uint32:range lastReadHex:&lastReadHex];
  [node.details appendRow:[NSString stringWithFormat:@"%.8lX", range.location]
                         :lastReadHex
                         :@"Command"
                         :[self getNameForCommand:symtab_command->cmd]];

  [node.details setAttributes:MVCellColorAttributeName,[NSColor greenColor],nil];

  [dataController read_uint32:range lastReadHex:&lastReadHex];
  [node.details appendRow:[NSString stringWithFormat:@"%.8lX", range.location]
                         :lastReadHex
                         :@"Command Size"
                         :[NSString stringWithFormat:@"%u", symtab_command->cmdsize]];
  
  [node.details setAttributes:MVCellColorAttributeName,[NSColor greenColor],
                              MVUnderlineAttributeName,@"YES",nil];
  
  [dataController read_uint32:range lastReadHex:&lastReadHex];
  [node.details appendRow:[NSString stringWithFormat:@"%.8lX", range.location]
                         :lastReadHex
                         :@"Symbol Table Offset"
                         :[NSString stringWithFormat:@"%u", symtab_command->symoff]];
  
  [dataController read_uint32:range lastReadHex:&lastReadHex];
  [node.details appendRow:[NSString stringWithFormat:@"%.8lX", range.location]
                         :lastReadHex
                         :@"Number of Symbols"
                         :[NSString stringWithFormat:@"%u", symtab_command->nsyms]];
  
  [dataController read_uint32:range lastReadHex:&lastReadHex];
  [node.details appendRow:[NSString stringWithFormat:@"%.8lX", range.location]
                         :lastReadHex
                         :@"String Table Offset"
                         :[NSString stringWithFormat:@"%u", symtab_command->stroff]];
  
  [dataController read_uint32:range lastReadHex:&lastReadHex];
  [node.details appendRow:[NSString stringWithFormat:@"%.8lX", range.location]
                         :lastReadHex
                         :@"String Table Size"
                         :[NSString stringWithFormat:@"%u", symtab_command->strsize]];
  return node;
}

//-----------------------------------------------------------------------------
- (MVNode *)createLCDysymtabNode:(MVNode *)parent
                       caption:(NSString *)caption
                      location:(uint32_t)location
              dysymtab_command:(struct dysymtab_command const *)dysymtab_command
{
  MVNodeSaver nodeSaver;
  MVNode * node = [parent insertChildWithDetails:caption location:location length:dysymtab_command->cmdsize saver:nodeSaver]; 
  
  NSRange range = NSMakeRange(location,0);
  NSString * lastReadHex;
  
  [dataController read_uint32:range lastReadHex:&lastReadHex];
  [node.details appendRow:[NSString stringWithFormat:@"%.8lX", range.location]
                         :lastReadHex
                         :@"Command"
                         :[self getNameForCommand:dysymtab_command->cmd]];

  [node.details setAttributes:MVCellColorAttributeName,[NSColor greenColor],nil];

  [dataController read_uint32:range lastReadHex:&lastReadHex];
  [node.details appendRow:[NSString stringWithFormat:@"%.8lX", range.location]
                         :lastReadHex
                         :@"Command Size"
                         :[NSString stringWithFormat:@"%u", dysymtab_command->cmdsize]];
  
  [node.details setAttributes:MVCellColorAttributeName,[NSColor greenColor],
                              MVUnderlineAttributeName,@"YES",nil];
  
  [dataController read_uint32:range lastReadHex:&lastReadHex];
  [node.details appendRow:[NSString stringWithFormat:@"%.8lX", range.location]
                         :lastReadHex
                         :@"LocSymbol Index"
                         :[NSString stringWithFormat:@"%u", dysymtab_command->ilocalsym]];
  
  [dataController read_uint32:range lastReadHex:&lastReadHex];
  [node.details appendRow:[NSString stringWithFormat:@"%.8lX", range.location]
                         :lastReadHex
                         :@"LocSymbol Number"
                         :[NSString stringWithFormat:@"%u", dysymtab_command->nlocalsym]];
  
  [dataController read_uint32:range lastReadHex:&lastReadHex];
  [node.details appendRow:[NSString stringWithFormat:@"%.8lX", range.location]
                         :lastReadHex
                         :@"Defined ExtSymbol Index"
                         :[NSString stringWithFormat:@"%u", dysymtab_command->iextdefsym]];

  [dataController read_uint32:range lastReadHex:&lastReadHex];
  [node.details appendRow:[NSString stringWithFormat:@"%.8lX", range.location]
                         :lastReadHex
                         :@"Defined ExtSymbol Number"
                         :[NSString stringWithFormat:@"%u", dysymtab_command->nextdefsym]];
  
  [dataController read_uint32:range lastReadHex:&lastReadHex];
  [node.details appendRow:[NSString stringWithFormat:@"%.8lX", range.location]
                         :lastReadHex
                         :@"Undef ExtSymbol Index"
                         :[NSString stringWithFormat:@"%u", dysymtab_command->iundefsym]];
  
  [dataController read_uint32:range lastReadHex:&lastReadHex];
  [node.details appendRow:[NSString stringWithFormat:@"%.8lX", range.location]
                         :lastReadHex
                         :@"Undef ExtSymbol Number"
                         :[NSString stringWithFormat:@"%u", dysymtab_command->nundefsym]];
  
  [dataController read_uint32:range lastReadHex:&lastReadHex];
  [node.details appendRow:[NSString stringWithFormat:@"%.8lX", range.location]
                         :lastReadHex
                         :@"TOC Offset"
                         :[NSString stringWithFormat:@"%u", dysymtab_command->tocoff]];
  
  [dataController read_uint32:range lastReadHex:&lastReadHex];
  [node.details appendRow:[NSString stringWithFormat:@"%.8lX", range.location]
                         :lastReadHex
                         :@"TOC Entries"
                         :[NSString stringWithFormat:@"%u", dysymtab_command->ntoc]];
  
  [dataController read_uint32:range lastReadHex:&lastReadHex];
  [node.details appendRow:[NSString stringWithFormat:@"%.8lX", range.location]
                         :lastReadHex
                         :@"Module Table Offset"
                         :[NSString stringWithFormat:@"%u", dysymtab_command->modtaboff]];
  
  [dataController read_uint32:range lastReadHex:&lastReadHex];
  [node.details appendRow:[NSString stringWithFormat:@"%.8lX", range.location]
                         :lastReadHex
                         :@"Module Table Entries"
                         :[NSString stringWithFormat:@"%u", dysymtab_command->nmodtab]];
  
  [dataController read_uint32:range lastReadHex:&lastReadHex];
  [node.details appendRow:[NSString stringWithFormat:@"%.8lX", range.location]
                         :lastReadHex
                         :@"ExtRef Table Offset"
                         :[NSString stringWithFormat:@"%u", dysymtab_command->extrefsymoff]];
  
  [dataController read_uint32:range lastReadHex:&lastReadHex];
  [node.details appendRow:[NSString stringWithFormat:@"%.8lX", range.location]
                         :lastReadHex
                         :@"ExtRef Table Entries"
                         :[NSString stringWithFormat:@"%u", dysymtab_command->nextrefsyms]];
  
  [dataController read_uint32:range lastReadHex:&lastReadHex];
  [node.details appendRow:[NSString stringWithFormat:@"%.8lX", range.location]
                         :lastReadHex
                         :@"IndSym Table Offset"
                         :[NSString stringWithFormat:@"%u", dysymtab_command->indirectsymoff]];
  
  [dataController read_uint32:range lastReadHex:&lastReadHex];
  [node.details appendRow:[NSString stringWithFormat:@"%.8lX", range.location]
                         :lastReadHex
                         :@"IndSym Table Entries"
                         :[NSString stringWithFormat:@"%u", dysymtab_command->nindirectsyms]];
  
  [dataController read_uint32:range lastReadHex:&lastReadHex];
  [node.details appendRow:[NSString stringWithFormat:@"%.8lX", range.location]
                         :lastReadHex
                         :@"ExtReloc Table Offset"
                         :[NSString stringWithFormat:@"%u", dysymtab_command->extreloff]];
  
  [dataController read_uint32:range lastReadHex:&lastReadHex];
  [node.details appendRow:[NSString stringWithFormat:@"%.8lX", range.location]
                         :lastReadHex
                         :@"ExtReloc Table Entries"
                         :[NSString stringWithFormat:@"%u", dysymtab_command->nextrel]];
  
  [dataController read_uint32:range lastReadHex:&lastReadHex];
  [node.details appendRow:[NSString stringWithFormat:@"%.8lX", range.location]
                         :lastReadHex
                         :@"LocReloc Table Offset"
                         :[NSString stringWithFormat:@"%u", dysymtab_command->locreloff]];
  
  [dataController read_uint32:range lastReadHex:&lastReadHex];
  [node.details appendRow:[NSString stringWithFormat:@"%.8lX", range.location]
                         :lastReadHex
                         :@"LocReloc Table Entries"
                         :[NSString stringWithFormat:@"%u", dysymtab_command->nlocrel]];
  return node;
}

//-----------------------------------------------------------------------------
- (MVNode *)createLCTwolevelHintsNode:(MVNode *)parent
                            caption:(NSString *)caption
                           location:(uint32_t)location
             twolevel_hints_command:(struct twolevel_hints_command const *)twolevel_hints_command
{
  MVNodeSaver nodeSaver;
  MVNode * node = [parent insertChildWithDetails:caption location:location length:twolevel_hints_command->cmdsize saver:nodeSaver]; 
  
  NSRange range = NSMakeRange(location,0);
  NSString * lastReadHex;
  
  [dataController read_uint32:range lastReadHex:&lastReadHex];
  [node.details appendRow:[NSString stringWithFormat:@"%.8lX", range.location]
                         :lastReadHex
                         :@"Command"
                         :[self getNameForCommand:twolevel_hints_command->cmd]];
  
  [node.details setAttributes:MVCellColorAttributeName,[NSColor greenColor],nil];

  [dataController read_uint32:range lastReadHex:&lastReadHex];
  [node.details appendRow:[NSString stringWithFormat:@"%.8lX", range.location]
                         :lastReadHex
                         :@"Command Size"
                         :[NSString stringWithFormat:@"%u", twolevel_hints_command->cmdsize]];
  
  [node.details setAttributes:MVCellColorAttributeName,[NSColor greenColor],
                              MVUnderlineAttributeName,@"YES",nil];
  
  [dataController read_uint32:range lastReadHex:&lastReadHex];
  [node.details appendRow:[NSString stringWithFormat:@"%.8lX", range.location]
                         :lastReadHex
                         :@"Offset"
                         :[NSString stringWithFormat:@"%u", twolevel_hints_command->offset]];
  
  [dataController read_uint32:range lastReadHex:&lastReadHex];
  [node.details appendRow:[NSString stringWithFormat:@"%.8lX", range.location]
                         :lastReadHex
                         :@"Number of Hints"
                         :[NSString stringWithFormat:@"%u", twolevel_hints_command->nhints]];
  return node;
}

//-----------------------------------------------------------------------------
- (MVNode *)createLCDylinkerNode:(MVNode *)parent
                       caption:(NSString *)caption
                      location:(uint32_t)location
              dylinker_command:(struct dylinker_command const *)dylinker_command
{
  MVNodeSaver nodeSaver;
  MVNode * node = [parent insertChildWithDetails:caption location:location length:dylinker_command->cmdsize saver:nodeSaver]; 
  
  NSRange range = NSMakeRange(location,0);
  NSString * lastReadHex;
  
  [dataController read_uint32:range lastReadHex:&lastReadHex];
  [node.details appendRow:[NSString stringWithFormat:@"%.8lX", range.location]
                         :lastReadHex
                         :@"Command"
                         :[self getNameForCommand:dylinker_command->cmd]];
  
  [node.details setAttributes:MVCellColorAttributeName,[NSColor greenColor],nil];

  [dataController read_uint32:range lastReadHex:&lastReadHex];
  [node.details appendRow:[NSString stringWithFormat:@"%.8lX", range.location]
                         :lastReadHex
                         :@"Command Size"
                         :[NSString stringWithFormat:@"%u", dylinker_command->cmdsize]];
  
  [node.details setAttributes:MVCellColorAttributeName,[NSColor greenColor],
                              MVUnderlineAttributeName,@"YES",nil];
  
  [dataController read_uint32:range lastReadHex:&lastReadHex];
  [node.details appendRow:[NSString stringWithFormat:@"%.8lX", range.location]
                         :lastReadHex
                         :@"Str Offset"
                         :[NSString stringWithFormat:@"%u", dylinker_command->name.offset]];
  
  [node.details setAttributes:MVUnderlineAttributeName,@"YES",nil];
  
  range = NSMakeRange(location + dylinker_command->name.offset,0);
  NSString * name = [dataController read_string:range lastReadHex:&lastReadHex];
  [node.details appendRow:[NSString stringWithFormat:@"%.8lX", range.location]
                         :lastReadHex
                         :@"Name"
                         :name];
  return node;
}

//-----------------------------------------------------------------------------
- (MVNode *)createLCPrebindChksumNode:(MVNode *)parent
                              caption:(NSString *)caption
                             location:(uint32_t)location
                prebind_cksum_command:(struct prebind_cksum_command const *)prebind_cksum_command
{
  MVNodeSaver nodeSaver;
  MVNode * node = [parent insertChildWithDetails:caption location:location length:prebind_cksum_command->cmdsize saver:nodeSaver]; 
  
  NSRange range = NSMakeRange(location,0);
  NSString * lastReadHex;
  
  [dataController read_uint32:range lastReadHex:&lastReadHex];
  [node.details appendRow:[NSString stringWithFormat:@"%.8lX", range.location]
                         :lastReadHex
                         :@"Command"
                         :[self getNameForCommand:prebind_cksum_command->cmd]];

  [node.details setAttributes:MVCellColorAttributeName,[NSColor greenColor],nil];
  
  [dataController read_uint32:range lastReadHex:&lastReadHex];
  [node.details appendRow:[NSString stringWithFormat:@"%.8lX", range.location]
                         :lastReadHex
                         :@"Command Size"
                         :[NSString stringWithFormat:@"%u", prebind_cksum_command->cmdsize]];
  
  [node.details setAttributes:MVCellColorAttributeName,[NSColor greenColor],
                              MVUnderlineAttributeName,@"YES",nil];
  
  [dataController read_uint32:range lastReadHex:&lastReadHex];
  [node.details appendRow:[NSString stringWithFormat:@"%.8lX", range.location]
                         :lastReadHex
                         :@"Checksum"
                         :[NSString stringWithFormat:@"0x%.8X",prebind_cksum_command->cksum]];
  return node;
}

  
//-----------------------------------------------------------------------------
- (MVNode *)createLCUUIDNode:(MVNode *)parent
                   caption:(NSString *)caption
                  location:(uint32_t)location
              uuid_command:(struct uuid_command const *)uuid_command
{
  MVNodeSaver nodeSaver;
  MVNode * node = [parent insertChildWithDetails:caption location:location length:uuid_command->cmdsize saver:nodeSaver]; 
  
  NSRange range = NSMakeRange(location,0);
  NSString * lastReadHex;
  
  [dataController read_uint32:range lastReadHex:&lastReadHex];
  [node.details appendRow:[NSString stringWithFormat:@"%.8lX", range.location]
                         :lastReadHex
                         :@"Command"
                         :[self getNameForCommand:uuid_command->cmd]];
  
  [node.details setAttributes:MVCellColorAttributeName,[NSColor greenColor],nil];

  [dataController read_uint32:range lastReadHex:&lastReadHex];
  [node.details appendRow:[NSString stringWithFormat:@"%.8lX", range.location]
                         :lastReadHex
                         :@"Command Size"
                         :[NSString stringWithFormat:@"%u", uuid_command->cmdsize]];
  
  [node.details setAttributes:MVCellColorAttributeName,[NSColor greenColor],
                              MVUnderlineAttributeName,@"YES",nil];
  
  [dataController read_bytes:range length:16 lastReadHex:&lastReadHex];
  [node.details appendRow:[NSString stringWithFormat:@"%.8lX", range.location]
                         :lastReadHex
                         :@"UUID"
                         :[NSString stringWithFormat:@"%@-%@-%@-%@-%@",
                          [lastReadHex substringWithRange:NSMakeRange(0,8)],
                          [lastReadHex substringWithRange:NSMakeRange(8,4)],
                          [lastReadHex substringWithRange:NSMakeRange(12,4)],
                          [lastReadHex substringWithRange:NSMakeRange(16,4)],
                          [lastReadHex substringWithRange:NSMakeRange(20,12)] ]];
  return node;
}

//-----------------------------------------------------------------------------
- (MVNode *)createLCThreadNode:(MVNode *)parent
                     caption:(NSString *)caption
                    location:(uint32_t)location
              thread_command:(struct thread_command const *)thread_command
{
  MVNodeSaver nodeSaver;
  MVNode * node = [parent insertChildWithDetails:caption location:location length:thread_command->cmdsize saver:nodeSaver]; 
  
  NSRange range = NSMakeRange(location,0);
  NSString * lastReadHex;
  
  [dataController read_uint32:range lastReadHex:&lastReadHex];
  [node.details appendRow:[NSString stringWithFormat:@"%.8lX", range.location]
                         :lastReadHex
                         :@"Command"
                         :[self getNameForCommand:thread_command->cmd]];
  
  [node.details setAttributes:MVCellColorAttributeName,[NSColor greenColor],nil];

  [dataController read_uint32:range lastReadHex:&lastReadHex];
  [node.details appendRow:[NSString stringWithFormat:@"%.8lX", range.location]
                         :lastReadHex
                         :@"Command Size"
                         :[NSString stringWithFormat:@"%u", thread_command->cmdsize]];
  
  [node.details setAttributes:MVCellColorAttributeName,[NSColor greenColor],
                              MVUnderlineAttributeName,@"YES",nil];
  
  MATCH_STRUCT(mach_header,imageOffset);
  if (mach_header->cputype == CPU_TYPE_I386 || mach_header->cputype == CPU_TYPE_X86_64)
  {
    MATCH_STRUCT(x86_thread_state,NSMaxRange(range))
    
    [dataController read_uint32:range lastReadHex:&lastReadHex];
    [node.details appendRow:[NSString stringWithFormat:@"%.8lX", range.location]
                           :lastReadHex
                           :@"Flavor"
                           :x86_thread_state->tsh.flavor == x86_THREAD_STATE32 ? @"x86_THREAD_STATE32" :
                            x86_thread_state->tsh.flavor == x86_FLOAT_STATE32 ? @"x86_FLOAT_STATE32" :
                            x86_thread_state->tsh.flavor == x86_EXCEPTION_STATE32 ? @"x86_EXCEPTION_STATE32" :
                            x86_thread_state->tsh.flavor == x86_THREAD_STATE64 ? @"x86_THREAD_STATE64" :                                     
                            x86_thread_state->tsh.flavor == x86_FLOAT_STATE64 ? @"x86_FLOAT_STATE64" :
                            x86_thread_state->tsh.flavor == x86_EXCEPTION_STATE64 ? @"x86_EXCEPTION_STATE64" :
                            x86_thread_state->tsh.flavor == x86_THREAD_STATE ? @"x86_THREAD_STATE" :
                            x86_thread_state->tsh.flavor == x86_FLOAT_STATE ? @"x86_FLOAT_STATE" :
                            x86_thread_state->tsh.flavor == x86_EXCEPTION_STATE ? @"x86_EXCEPTION_STATE" :
                            x86_thread_state->tsh.flavor == x86_DEBUG_STATE32 ? @"x86_DEBUG_STATE32" :
                            x86_thread_state->tsh.flavor == x86_DEBUG_STATE64 ? @"x86_DEBUG_STATE64" :
                            x86_thread_state->tsh.flavor == x86_DEBUG_STATE ? @"x86_DEBUG_STATE" :
                            x86_thread_state->tsh.flavor == THREAD_STATE_NONE ? @"THREAD_STATE_NONE" : @"???"];
    
    [dataController read_uint32:range lastReadHex:&lastReadHex];
    [node.details appendRow:[NSString stringWithFormat:@"%.8lX", range.location]
                           :lastReadHex
                           :@"Count"
                           :[NSString stringWithFormat:@"%u", x86_thread_state->tsh.count]];
    
    [node.details setAttributes:MVUnderlineAttributeName,@"YES",nil];
    
    if (x86_thread_state->tsh.flavor == x86_THREAD_STATE32)
    {
      entryPoint = x86_thread_state->uts.ts32.__eip;

      NSDictionary * stateDict = [NSDictionary dictionaryWithObjectsAndKeys:
                                  [NSString stringWithFormat:@"%u",x86_thread_state->uts.ts32.__eax],   @"eax",
                                  [NSString stringWithFormat:@"%u",x86_thread_state->uts.ts32.__ebx],   @"ebx",
                                  [NSString stringWithFormat:@"%u",x86_thread_state->uts.ts32.__ecx],   @"ecx",
                                  [NSString stringWithFormat:@"%u",x86_thread_state->uts.ts32.__edx],   @"edx",
                                  [NSString stringWithFormat:@"%u",x86_thread_state->uts.ts32.__edi],   @"edi",
                                  [NSString stringWithFormat:@"%u",x86_thread_state->uts.ts32.__esi],   @"esi",
                                  [NSString stringWithFormat:@"%u",x86_thread_state->uts.ts32.__ebp],   @"ebp",
                                  [NSString stringWithFormat:@"%u",x86_thread_state->uts.ts32.__esp],   @"esp",
                                  [NSString stringWithFormat:@"%u",x86_thread_state->uts.ts32.__ss],    @"ss", 
                                  [NSString stringWithFormat:@"%u",x86_thread_state->uts.ts32.__eflags],@"eflags",
                                  [NSString stringWithFormat:@"%u",x86_thread_state->uts.ts32.__eip],   @"eip",
                                  [NSString stringWithFormat:@"%u",x86_thread_state->uts.ts32.__cs],    @"cs", 
                                  [NSString stringWithFormat:@"%u",x86_thread_state->uts.ts32.__ds],    @"ds", 
                                  [NSString stringWithFormat:@"%u",x86_thread_state->uts.ts32.__es],    @"es", 
                                  [NSString stringWithFormat:@"%u",x86_thread_state->uts.ts32.__fs],    @"fs", 
                                  [NSString stringWithFormat:@"%u",x86_thread_state->uts.ts32.__gs],    @"gs", 
                                  nil];
      
      for (id key in [NSArray arrayWithObjects:
                      @"eax",@"ebx",@"ecx",@"edx",
                      @"edi",@"esi",@"ebp",@"esp",
                      @"ss",@"eflags",@"eip",@"cs", 
                      @"ds",@"es",@"fs",@"gs",nil]) 
      {
        [dataController read_uint32:range lastReadHex:&lastReadHex];
        [node.details appendRow:[NSString stringWithFormat:@"%.8lX", range.location]
                               :lastReadHex
                               :key
                               :[stateDict objectForKey:key]];
      }
    }
    else if (x86_thread_state->tsh.flavor == x86_THREAD_STATE64)
    {
      entryPoint = x86_thread_state->uts.ts64.__rip;
      
      NSDictionary * stateDict = [NSDictionary dictionaryWithObjectsAndKeys:
                                  [NSString stringWithFormat:@"%qu",x86_thread_state->uts.ts64.__rax], @"rax",
                                  [NSString stringWithFormat:@"%qu",x86_thread_state->uts.ts64.__rbx], @"rbx",
                                  [NSString stringWithFormat:@"%qu",x86_thread_state->uts.ts64.__rcx], @"rcx",
                                  [NSString stringWithFormat:@"%qu",x86_thread_state->uts.ts64.__rdx], @"rdx",
                                  [NSString stringWithFormat:@"%qu",x86_thread_state->uts.ts64.__rdi], @"rdi",
                                  [NSString stringWithFormat:@"%qu",x86_thread_state->uts.ts64.__rsi], @"rsi",
                                  [NSString stringWithFormat:@"%qu",x86_thread_state->uts.ts64.__rbp], @"rbp",
                                  [NSString stringWithFormat:@"%qu",x86_thread_state->uts.ts64.__rsp], @"rsp",
                                  [NSString stringWithFormat:@"%qu",x86_thread_state->uts.ts64.__r8], @"r8",
                                  [NSString stringWithFormat:@"%qu",x86_thread_state->uts.ts64.__r9], @"r9", 
                                  [NSString stringWithFormat:@"%qu",x86_thread_state->uts.ts64.__r10], @"r10", 
                                  [NSString stringWithFormat:@"%qu",x86_thread_state->uts.ts64.__r11], @"r11", 
                                  [NSString stringWithFormat:@"%qu",x86_thread_state->uts.ts64.__r12], @"r12", 
                                  [NSString stringWithFormat:@"%qu",x86_thread_state->uts.ts64.__r13], @"r13", 
                                  [NSString stringWithFormat:@"%qu",x86_thread_state->uts.ts64.__r14], @"r14", 
                                  [NSString stringWithFormat:@"%qu",x86_thread_state->uts.ts64.__r15], @"r15", 
                                  [NSString stringWithFormat:@"%qu",x86_thread_state->uts.ts64.__rip], @"rip",
                                  [NSString stringWithFormat:@"%qu",x86_thread_state->uts.ts64.__rflags], @"rflags",
                                  [NSString stringWithFormat:@"%qu",x86_thread_state->uts.ts64.__cs], @"cs",
                                  [NSString stringWithFormat:@"%qu",x86_thread_state->uts.ts64.__fs], @"fs", 
                                  [NSString stringWithFormat:@"%qu",x86_thread_state->uts.ts64.__gs], @"gs", nil];
      
      for (id key in [NSArray arrayWithObjects:
                      @"rax",@"rbx",@"rcx",@"rdx",@"rdi",@"rsi",@"rbp",@"rsp",
                      @"r8",@"r9", @"r10", @"r11", @"r12", @"r13", @"r14", @"r15", 
                      @"rip",@"rflags",@"cs",@"fs", @"gs", nil])
      {
        [dataController read_uint64:range lastReadHex:&lastReadHex];
        [node.details appendRow:[NSString stringWithFormat:@"%.8lX", range.location]
                               :lastReadHex
                               :key
                               :[stateDict objectForKey:key]];
      }
    }
  }
  else if (mach_header->cputype == CPU_TYPE_ARM)
  {
    struct arm_thread_state
    {
      uint32_t  flavor;
      uint32_t  count;
      union 
      {
        struct thread_state
        {
          uint32_t	__r[13];      // General purpose register r0-r12
          uint32_t	__sp;         // Stack pointer r13
          uint32_t	__lr;         // Link register r14
          uint32_t	__pc;         // Program counter r15
          uint32_t	__cpsr;       // Current program status register
        } ts;
        
        struct vfp_state
        {
          uint32_t  __r[64];
          uint32_t  __fpscr;
        } vs;
        
        struct exception_state
        {
        	uint32_t	__exception;  // number of arm exception taken
          uint32_t	__fsr;        // Fault status
          uint32_t	__far;        // Virtual Fault Address
        } es;
        
        struct debug_state
        {
          uint32_t  __bvr[16];
          uint32_t  __bcr[16];
          uint32_t  __wvr[16];
          uint32_t  __wcr[16];
        } ds;
      } uts;
    };

    MATCH_STRUCT(arm_thread_state,NSMaxRange(range))
    
    [dataController read_uint32:range lastReadHex:&lastReadHex];
    [node.details appendRow:[NSString stringWithFormat:@"%.8lX", range.location]
                           :lastReadHex
                           :@"Flavor"
                           :arm_thread_state->flavor == 1 ? @"ARM_THREAD_STATE" :
                            arm_thread_state->flavor == 2 ? @"ARM_VFP_STATE" :
                            arm_thread_state->flavor == 3 ? @"ARM_EXCEPTION_STATE" :
                            arm_thread_state->flavor == 4 ? @"ARM_DEBUG_STATE" :                                     
                            arm_thread_state->flavor == 5 ? @"THREAD_STATE_NONE" : @"???"];
    
    [dataController read_uint32:range lastReadHex:&lastReadHex];
    [node.details appendRow:[NSString stringWithFormat:@"%.8lX", range.location]
                           :lastReadHex
                           :@"Count"
                           :[NSString stringWithFormat:@"%u", arm_thread_state->count]];
    
    [node.details setAttributes:MVUnderlineAttributeName,@"YES",nil];
    
    #pragma message "TODO: complete the remaining favors"
    
    if (arm_thread_state->flavor == 1)
    {
      entryPoint = arm_thread_state->uts.ts.__pc;
      
      NSDictionary * stateDict = [NSDictionary dictionaryWithObjectsAndKeys:
                                  [NSString stringWithFormat:@"%u",arm_thread_state->uts.ts.__r[0]],   @"r0",
                                  [NSString stringWithFormat:@"%u",arm_thread_state->uts.ts.__r[1]],   @"r1",
                                  [NSString stringWithFormat:@"%u",arm_thread_state->uts.ts.__r[2]],   @"r2",
                                  [NSString stringWithFormat:@"%u",arm_thread_state->uts.ts.__r[3]],   @"r3",
                                  [NSString stringWithFormat:@"%u",arm_thread_state->uts.ts.__r[4]],   @"r4",
                                  [NSString stringWithFormat:@"%u",arm_thread_state->uts.ts.__r[5]],   @"r5",
                                  [NSString stringWithFormat:@"%u",arm_thread_state->uts.ts.__r[6]],   @"r6",
                                  [NSString stringWithFormat:@"%u",arm_thread_state->uts.ts.__r[7]],   @"r7",
                                  [NSString stringWithFormat:@"%u",arm_thread_state->uts.ts.__r[8]],   @"r8", 
                                  [NSString stringWithFormat:@"%u",arm_thread_state->uts.ts.__r[9]],   @"r9",
                                  [NSString stringWithFormat:@"%u",arm_thread_state->uts.ts.__r[10]],  @"r10",
                                  [NSString stringWithFormat:@"%u",arm_thread_state->uts.ts.__r[11]],  @"r11", 
                                  [NSString stringWithFormat:@"%u",arm_thread_state->uts.ts.__r[12]],  @"r12", 
                                  [NSString stringWithFormat:@"%u",arm_thread_state->uts.ts.__sp],     @"sp", 
                                  [NSString stringWithFormat:@"%u",arm_thread_state->uts.ts.__lr],     @"lr", 
                                  [NSString stringWithFormat:@"%u",arm_thread_state->uts.ts.__pc],     @"pc", 
                                  [NSString stringWithFormat:@"%u",arm_thread_state->uts.ts.__cpsr],   @"cpsr", 
                                  nil];
      
      for (id key in [NSArray arrayWithObjects:
                      @"r0", @"r1", @"r2", @"r3", @"r4", @"r5", @"r6",
                      @"r7", @"r8", @"r9", @"r10",@"r11", @"r12", 
                      @"sp", @"lr", @"pc", @"cpsr", nil])
      {
        [dataController read_uint32:range lastReadHex:&lastReadHex];
        [node.details appendRow:[NSString stringWithFormat:@"%.8lX", range.location]
                               :lastReadHex
                               :key
                               :[stateDict objectForKey:key]];
      }
    }
    else if (mach_header->cputype == CPU_TYPE_ARM64)
    {
#pragma message "TODO: ARM64"
    }
  }
  
  return node;
}

//-----------------------------------------------------------------------------
- (MVNode *)createLCDylibNode:(MVNode *)parent
                    caption:(NSString *)caption
                   location:(uint32_t)location
              dylib_command:(struct dylib_command const *)dylib_command
{
  MVNodeSaver nodeSaver;
  MVNode * node = [parent insertChildWithDetails:caption location:location length:dylib_command->cmdsize saver:nodeSaver]; 
  
  NSRange range = NSMakeRange(location,0);
  NSString * lastReadHex;
  
  [dataController read_uint32:range lastReadHex:&lastReadHex];
  [node.details appendRow:[NSString stringWithFormat:@"%.8lX", range.location]
                         :lastReadHex
                         :@"Command"
                         :[self getNameForCommand:dylib_command->cmd]];

  [node.details setAttributes:MVCellColorAttributeName,[NSColor greenColor],nil];

  [dataController read_uint32:range lastReadHex:&lastReadHex];
  [node.details appendRow:[NSString stringWithFormat:@"%.8lX", range.location]
                         :lastReadHex
                         :@"Command Size"
                         :[NSString stringWithFormat:@"%u", dylib_command->cmdsize]];
  
  [node.details setAttributes:MVCellColorAttributeName,[NSColor greenColor],
                              MVUnderlineAttributeName,@"YES",nil];
  
  [dataController read_uint32:range lastReadHex:&lastReadHex];
  [node.details appendRow:[NSString stringWithFormat:@"%.8lX", range.location]
                         :lastReadHex
                         :@"Str Offset"
                         :[NSString stringWithFormat:@"%u", dylib_command->dylib.name.offset]];
  
  [dataController read_uint32:range lastReadHex:&lastReadHex];
  time_t time = (time_t)dylib_command->dylib.timestamp;
  [node.details appendRow:[NSString stringWithFormat:@"%.8lX", range.location]
                         :lastReadHex
                         :@"Time Stamp"
                         :[NSString stringWithFormat:@"%s", ctime(&time)]];
  
  [dataController read_uint32:range lastReadHex:&lastReadHex];
  [node.details appendRow:[NSString stringWithFormat:@"%.8lX", range.location]
                         :lastReadHex
                         :@"Current Version"
                         :[NSString stringWithFormat:@"%u.%u.%u",  
                           (dylib_command->dylib.current_version >> 16),
                           ((dylib_command->dylib.current_version >> 8) & 0xff),
                           (dylib_command->dylib.current_version & 0xff)]];
  
  [dataController read_uint32:range lastReadHex:&lastReadHex];
  [node.details appendRow:[NSString stringWithFormat:@"%.8lX", range.location]
                         :lastReadHex
                         :@"Compatibility Version"
                         :[NSString stringWithFormat:@"%u.%u.%u",  
                           (dylib_command->dylib.compatibility_version >> 16),
                           ((dylib_command->dylib.compatibility_version >> 8) & 0xff),
                           (dylib_command->dylib.compatibility_version & 0xff)]];

  [node.details setAttributes:MVUnderlineAttributeName,@"YES",nil];
  
  range = NSMakeRange(location + dylib_command->dylib.name.offset,0);
  NSString * name = [dataController read_string:range lastReadHex:&lastReadHex];
  [node.details appendRow:[NSString stringWithFormat:@"%.8lX", range.location]
                         :lastReadHex
                         :@"Name"
                         :name];
  return node;
}

//-----------------------------------------------------------------------------
- (MVNode *)createLCLinkeditDataNode:(MVNode *)parent
                           caption:(NSString *)caption
                          location:(uint32_t)location
             linkedit_data_command:(struct linkedit_data_command const *)linkedit_data_command
{
  MVNodeSaver nodeSaver;
  MVNode * node = [parent insertChildWithDetails:caption location:location length:linkedit_data_command->cmdsize saver:nodeSaver]; 
  
  NSRange range = NSMakeRange(location,0);
  NSString * lastReadHex;
  
  [dataController read_uint32:range lastReadHex:&lastReadHex];
  [node.details appendRow:[NSString stringWithFormat:@"%.8lX", range.location]
                         :lastReadHex
                         :@"Command"
                         :[self getNameForCommand:linkedit_data_command->cmd]];

  [node.details setAttributes:MVCellColorAttributeName,[NSColor greenColor],nil];

  [dataController read_uint32:range lastReadHex:&lastReadHex];
  [node.details appendRow:[NSString stringWithFormat:@"%.8lX", range.location]
                         :lastReadHex
                         :@"Command Size"
                         :[NSString stringWithFormat:@"%u", linkedit_data_command->cmdsize]];
  
  [node.details setAttributes:MVCellColorAttributeName,[NSColor greenColor],
                              MVUnderlineAttributeName,@"YES",nil];
  
  [dataController read_uint32:range lastReadHex:&lastReadHex];
  [node.details appendRow:[NSString stringWithFormat:@"%.8lX", range.location]
                         :lastReadHex
                         :@"Data Offset"
                         :[NSString stringWithFormat:@"%u", linkedit_data_command->dataoff]];
  
  [dataController read_uint32:range lastReadHex:&lastReadHex];
  [node.details appendRow:[NSString stringWithFormat:@"%.8lX", range.location]
                         :lastReadHex
                         :@"Data Size"
                         :[NSString stringWithFormat:@"%u", linkedit_data_command->datasize]];
  return node;
}

//-----------------------------------------------------------------------------
- (MVNode *)createLCRoutinesNode:(MVNode *)parent
                         caption:(NSString *)caption
                        location:(uint32_t)location
                routines_command:(struct routines_command const *)routines_command
{
  MVNodeSaver nodeSaver;
  MVNode * node = [parent insertChildWithDetails:caption location:location length:routines_command->cmdsize saver:nodeSaver]; 
  
  NSRange range = NSMakeRange(location,0);
  NSString * lastReadHex;
  
  [dataController read_uint32:range lastReadHex:&lastReadHex];
  [node.details appendRow:[NSString stringWithFormat:@"%.8lX", range.location]
                         :lastReadHex
                         :@"Command"
                         :[self getNameForCommand:routines_command->cmd]];

  [node.details setAttributes:MVCellColorAttributeName,[NSColor greenColor],nil];

  [dataController read_uint32:range lastReadHex:&lastReadHex];
  [node.details appendRow:[NSString stringWithFormat:@"%.8lX", range.location]
                         :lastReadHex
                         :@"Command Size"
                         :[NSString stringWithFormat:@"%u", routines_command->cmdsize]];
  
  [node.details setAttributes:MVCellColorAttributeName,[NSColor greenColor],
                              MVUnderlineAttributeName,@"YES",nil];
  
  [dataController read_uint32:range lastReadHex:&lastReadHex];
  [node.details appendRow:[NSString stringWithFormat:@"%.8lX", range.location]
                         :lastReadHex
                         :@"Init Address"
                         :[NSString stringWithFormat:@"0x%X", routines_command->init_address]];

  [dataController read_uint32:range lastReadHex:&lastReadHex];
  [node.details appendRow:[NSString stringWithFormat:@"%.8lX", range.location]
                         :lastReadHex
                         :@"Init Module"
                         :[NSString stringWithFormat:@"%u", routines_command->init_module]];

  [dataController read_uint32:range lastReadHex:&lastReadHex];
  [node.details appendRow:[NSString stringWithFormat:@"%.8lX", range.location]
                         :lastReadHex
                         :@"Reserved1"
                         :[NSString stringWithFormat:@"%u", routines_command->reserved1]];
  
  [dataController read_uint32:range lastReadHex:&lastReadHex];
  [node.details appendRow:[NSString stringWithFormat:@"%.8lX", range.location]
                         :lastReadHex
                         :@"Reserved2"
                         :[NSString stringWithFormat:@"%u", routines_command->reserved2]];
  
  [dataController read_uint32:range lastReadHex:&lastReadHex];
  [node.details appendRow:[NSString stringWithFormat:@"%.8lX", range.location]
                         :lastReadHex
                         :@"Reserved3"
                         :[NSString stringWithFormat:@"%u", routines_command->reserved3]];
  
  [dataController read_uint32:range lastReadHex:&lastReadHex];
  [node.details appendRow:[NSString stringWithFormat:@"%.8lX", range.location]
                         :lastReadHex
                         :@"Reserved4"
                         :[NSString stringWithFormat:@"%u", routines_command->reserved4]];
  
  [dataController read_uint32:range lastReadHex:&lastReadHex];
  [node.details appendRow:[NSString stringWithFormat:@"%.8lX", range.location]
                         :lastReadHex
                         :@"Reserved5"
                         :[NSString stringWithFormat:@"%u", routines_command->reserved5]];
  
  [dataController read_uint32:range lastReadHex:&lastReadHex];
  [node.details appendRow:[NSString stringWithFormat:@"%.8lX", range.location]
                         :lastReadHex
                         :@"Reserved6"
                         :[NSString stringWithFormat:@"%u", routines_command->reserved6]];
  return node;
}

//-----------------------------------------------------------------------------
- (MVNode *)createLCRoutines64Node:(MVNode *)parent
                           caption:(NSString *)caption
                          location:(uint32_t)location
               routines_command_64:(struct routines_command_64 const *)routines_command_64
{
  MVNodeSaver nodeSaver;
  MVNode * node = [parent insertChildWithDetails:caption location:location length:routines_command_64->cmdsize saver:nodeSaver]; 
  
  NSRange range = NSMakeRange(location,0);
  NSString * lastReadHex;
  
  [dataController read_uint32:range lastReadHex:&lastReadHex];
  [node.details appendRow:[NSString stringWithFormat:@"%.8lX", range.location]
                         :lastReadHex
                         :@"Command"
                         :[self getNameForCommand:routines_command_64->cmd]];

  [node.details setAttributes:MVCellColorAttributeName,[NSColor greenColor],nil];

  [dataController read_uint32:range lastReadHex:&lastReadHex];
  [node.details appendRow:[NSString stringWithFormat:@"%.8lX", range.location]
                         :lastReadHex
                         :@"Command Size"
                         :[NSString stringWithFormat:@"%u", routines_command_64->cmdsize]];
  
  [node.details setAttributes:MVCellColorAttributeName,[NSColor greenColor],
                              MVUnderlineAttributeName,@"YES",nil];
  
  [dataController read_uint64:range lastReadHex:&lastReadHex];
  [node.details appendRow:[NSString stringWithFormat:@"%.8lX", range.location]
                         :lastReadHex
                         :@"Init Address"
                         :[NSString stringWithFormat:@"%qu", routines_command_64->init_address]];
  
  [dataController read_uint64:range lastReadHex:&lastReadHex];
  [node.details appendRow:[NSString stringWithFormat:@"%.8lX", range.location]
                         :lastReadHex
                         :@"Init Module"
                         :[NSString stringWithFormat:@"%qu", routines_command_64->init_module]];
  
  [dataController read_uint64:range lastReadHex:&lastReadHex];
  [node.details appendRow:[NSString stringWithFormat:@"%.8lX", range.location]
                         :lastReadHex
                         :@"Reserved1"
                         :[NSString stringWithFormat:@"%qu", routines_command_64->reserved1]];
  
  [dataController read_uint64:range lastReadHex:&lastReadHex];
  [node.details appendRow:[NSString stringWithFormat:@"%.8lX", range.location]
                         :lastReadHex
                         :@"Reserved2"
                         :[NSString stringWithFormat:@"%qu", routines_command_64->reserved2]];
  
  [dataController read_uint64:range lastReadHex:&lastReadHex];
  [node.details appendRow:[NSString stringWithFormat:@"%.8lX", range.location]
                         :lastReadHex
                         :@"Reserved3"
                         :[NSString stringWithFormat:@"%qu", routines_command_64->reserved3]];
  
  [dataController read_uint64:range lastReadHex:&lastReadHex];
  [node.details appendRow:[NSString stringWithFormat:@"%.8lX", range.location]
                         :lastReadHex
                         :@"Reserved4"
                         :[NSString stringWithFormat:@"%qu", routines_command_64->reserved4]];
  
  [dataController read_uint64:range lastReadHex:&lastReadHex];
  [node.details appendRow:[NSString stringWithFormat:@"%.8lX", range.location]
                         :lastReadHex
                         :@"Reserved5"
                         :[NSString stringWithFormat:@"%qu", routines_command_64->reserved5]];
  
  [dataController read_uint64:range lastReadHex:&lastReadHex];
  [node.details appendRow:[NSString stringWithFormat:@"%.8lX", range.location]
                         :lastReadHex
                         :@"Reserved6"
                         :[NSString stringWithFormat:@"%qu", routines_command_64->reserved6]];
  return node;
}

//-----------------------------------------------------------------------------
- (MVNode *)createLCSubFrameworkNode:(MVNode *)parent
                             caption:(NSString *)caption
                            location:(uint32_t)location
               sub_framework_command:(struct sub_framework_command const *)sub_framework_command
{
  MVNodeSaver nodeSaver;
  MVNode * node = [parent insertChildWithDetails:caption location:location length:sub_framework_command->cmdsize saver:nodeSaver]; 
  
  NSRange range = NSMakeRange(location,0);
  NSString * lastReadHex;
  
  [dataController read_uint32:range lastReadHex:&lastReadHex];
  [node.details appendRow:[NSString stringWithFormat:@"%.8lX", range.location]
                         :lastReadHex
                         :@"Command"
                         :[self getNameForCommand:sub_framework_command->cmd]];

  [node.details setAttributes:MVCellColorAttributeName,[NSColor greenColor],nil];

  [dataController read_uint32:range lastReadHex:&lastReadHex];
  [node.details appendRow:[NSString stringWithFormat:@"%.8lX", range.location]
                         :lastReadHex
                         :@"Command Size"
                         :[NSString stringWithFormat:@"%u", sub_framework_command->cmdsize]];
  
  [node.details setAttributes:MVCellColorAttributeName,[NSColor greenColor],
                              MVUnderlineAttributeName,@"YES",nil];
  
  [dataController read_uint32:range lastReadHex:&lastReadHex];
  [node.details appendRow:[NSString stringWithFormat:@"%.8lX", range.location]
                         :lastReadHex
                         :@"Str Offset"
                         :[NSString stringWithFormat:@"%u", sub_framework_command->umbrella.offset]];
  
  [node.details setAttributes:MVUnderlineAttributeName,@"YES",nil];

  range = NSMakeRange(location + sub_framework_command->umbrella.offset,0);
  NSString * name = [dataController read_string:range lastReadHex:&lastReadHex];
  [node.details appendRow:[NSString stringWithFormat:@"%.8lX", range.location]
                         :lastReadHex
                         :@"Umbrella"
                         :name];
  return node;
}

//-----------------------------------------------------------------------------
- (MVNode *)createLCSubUmbrellaNode:(MVNode *)parent
                            caption:(NSString *)caption
                           location:(uint32_t)location
               sub_umbrella_command:(struct sub_umbrella_command const *)sub_umbrella_command
{
  MVNodeSaver nodeSaver;
  MVNode * node = [parent insertChildWithDetails:caption location:location length:sub_umbrella_command->cmdsize saver:nodeSaver]; 
  
  NSRange range = NSMakeRange(location,0);
  NSString * lastReadHex;
  
  [dataController read_uint32:range lastReadHex:&lastReadHex];
  [node.details appendRow:[NSString stringWithFormat:@"%.8lX", range.location]
                         :lastReadHex
                         :@"Command"
                         :[self getNameForCommand:sub_umbrella_command->cmd]];

  [node.details setAttributes:MVCellColorAttributeName,[NSColor greenColor],nil];

  [dataController read_uint32:range lastReadHex:&lastReadHex];
  [node.details appendRow:[NSString stringWithFormat:@"%.8lX", range.location]
                         :lastReadHex
                         :@"Command Size"
                         :[NSString stringWithFormat:@"%u", sub_umbrella_command->cmdsize]];
  
  [node.details setAttributes:MVCellColorAttributeName,[NSColor greenColor],
                              MVUnderlineAttributeName,@"YES",nil];
  
  [dataController read_uint32:range lastReadHex:&lastReadHex];
  [node.details appendRow:[NSString stringWithFormat:@"%.8lX", range.location]
                         :lastReadHex
                         :@"Str Offset"
                         :[NSString stringWithFormat:@"%u", sub_umbrella_command->sub_umbrella.offset]];
  
  [node.details setAttributes:MVUnderlineAttributeName,@"YES",nil];

  range = NSMakeRange(location + sub_umbrella_command->sub_umbrella.offset,0);
  NSString * name = [dataController read_string:range lastReadHex:&lastReadHex];
  [node.details appendRow:[NSString stringWithFormat:@"%.8lX", range.location]
                         :lastReadHex
                         :@"Sub Umbrella"
                         :name];
  return node;
}

//-----------------------------------------------------------------------------
- (MVNode *)createLCSubClientNode:(MVNode *)parent
                          caption:(NSString *)caption
                         location:(uint32_t)location
               sub_client_command:(struct sub_client_command const *)sub_client_command
{
  MVNodeSaver nodeSaver;
  MVNode * node = [parent insertChildWithDetails:caption location:location length:sub_client_command->cmdsize saver:nodeSaver]; 
  
  NSRange range = NSMakeRange(location,0);
  NSString * lastReadHex;
  
  [dataController read_uint32:range lastReadHex:&lastReadHex];
  [node.details appendRow:[NSString stringWithFormat:@"%.8lX", range.location]
                         :lastReadHex
                         :@"Command"
                         :[self getNameForCommand:sub_client_command->cmd]];
  
  [node.details setAttributes:MVCellColorAttributeName,[NSColor greenColor],nil];

  [dataController read_uint32:range lastReadHex:&lastReadHex];
  [node.details appendRow:[NSString stringWithFormat:@"%.8lX", range.location]
                         :lastReadHex
                         :@"Command Size"
                         :[NSString stringWithFormat:@"%u", sub_client_command->cmdsize]];
  
  [node.details setAttributes:MVCellColorAttributeName,[NSColor greenColor],
                              MVUnderlineAttributeName,@"YES",nil];
  
  [dataController read_uint32:range lastReadHex:&lastReadHex];
  [node.details appendRow:[NSString stringWithFormat:@"%.8lX", range.location]
                         :lastReadHex
                         :@"Str Offset"
                         :[NSString stringWithFormat:@"%u", sub_client_command->client.offset]];
  
  [node.details setAttributes:MVUnderlineAttributeName,@"YES",nil];

  range = NSMakeRange(location + sub_client_command->client.offset,0);
  NSString * name = [dataController read_string:range lastReadHex:&lastReadHex];
  [node.details appendRow:[NSString stringWithFormat:@"%.8lX", range.location]
                         :lastReadHex
                         :@"Client"
                         :name];
  return node;
}

//-----------------------------------------------------------------------------
- (MVNode *)createLCSubLibraryNode:(MVNode *)parent
                           caption:(NSString *)caption
                          location:(uint32_t)location
               sub_library_command:(struct sub_library_command const *)sub_library_command
{
  MVNodeSaver nodeSaver;
  MVNode * node = [parent insertChildWithDetails:caption location:location length:sub_library_command->cmdsize saver:nodeSaver]; 
  
  NSRange range = NSMakeRange(location,0);
  NSString * lastReadHex;
  
  [dataController read_uint32:range lastReadHex:&lastReadHex];
  [node.details appendRow:[NSString stringWithFormat:@"%.8lX", range.location]
                         :lastReadHex
                         :@"Command"
                         :[self getNameForCommand:sub_library_command->cmd]];
  
  [node.details setAttributes:MVCellColorAttributeName,[NSColor greenColor],nil];

  [dataController read_uint32:range lastReadHex:&lastReadHex];
  [node.details appendRow:[NSString stringWithFormat:@"%.8lX", range.location]
                         :lastReadHex
                         :@"Command Size"
                         :[NSString stringWithFormat:@"%u", sub_library_command->cmdsize]];
  
  [node.details setAttributes:MVCellColorAttributeName,[NSColor greenColor],
                              MVUnderlineAttributeName,@"YES",nil];
  
  [dataController read_uint32:range lastReadHex:&lastReadHex];
  [node.details appendRow:[NSString stringWithFormat:@"%.8lX", range.location]
                         :lastReadHex
                         :@"Str Offset"
                         :[NSString stringWithFormat:@"%u", sub_library_command->sub_library.offset]];
  
  [node.details setAttributes:MVUnderlineAttributeName,@"YES",nil];

  range = NSMakeRange(location + sub_library_command->sub_library.offset,0);
  NSString * name = [dataController read_string:range lastReadHex:&lastReadHex];
  [node.details appendRow:[NSString stringWithFormat:@"%.8lX", range.location]
                         :lastReadHex
                         :@"Sub Library"
                         :name];
  return node;
}

//-----------------------------------------------------------------------------
- (MVNode *)createLCDyldInfoNode:(MVNode *)parent
                         caption:(NSString *)caption
                        location:(uint32_t)location
               dyld_info_command:(struct dyld_info_command const *)dyld_info_command
{
  MVNodeSaver nodeSaver;
  MVNode * node = [parent insertChildWithDetails:caption location:location length:dyld_info_command->cmdsize saver:nodeSaver]; 
  
  NSRange range = NSMakeRange(location,0);
  NSString * lastReadHex;
  
  [dataController read_uint32:range lastReadHex:&lastReadHex];
  [node.details appendRow:[NSString stringWithFormat:@"%.8lX", range.location]
                         :lastReadHex
                         :@"Command"
                         :[self getNameForCommand:dyld_info_command->cmd]];
  
  [node.details setAttributes:MVCellColorAttributeName,[NSColor greenColor],nil];

  [dataController read_uint32:range lastReadHex:&lastReadHex];
  [node.details appendRow:[NSString stringWithFormat:@"%.8lX", range.location]
                         :lastReadHex
                         :@"Command Size"
                         :[NSString stringWithFormat:@"%u", dyld_info_command->cmdsize]];
  
  [node.details setAttributes:MVCellColorAttributeName,[NSColor greenColor],
                              MVUnderlineAttributeName,@"YES",nil];
  
  [dataController read_uint32:range lastReadHex:&lastReadHex];
  [node.details appendRow:[NSString stringWithFormat:@"%.8lX", range.location]
                         :lastReadHex
                         :@"Rebase Info Offset"
                         :[NSString stringWithFormat:@"%u", dyld_info_command->rebase_off]];

  [dataController read_uint32:range lastReadHex:&lastReadHex];
  [node.details appendRow:[NSString stringWithFormat:@"%.8lX", range.location]
                         :lastReadHex
                         :@"Rebase Info Size"
                         :[NSString stringWithFormat:@"%u", dyld_info_command->rebase_size]];
  
  [dataController read_uint32:range lastReadHex:&lastReadHex];
  [node.details appendRow:[NSString stringWithFormat:@"%.8lX", range.location]
                         :lastReadHex
                         :@"Binding Info Offset"
                         :[NSString stringWithFormat:@"%u", dyld_info_command->bind_off]];
  
  [dataController read_uint32:range lastReadHex:&lastReadHex];
  [node.details appendRow:[NSString stringWithFormat:@"%.8lX", range.location]
                         :lastReadHex
                         :@"Binding Info Size"
                         :[NSString stringWithFormat:@"%u", dyld_info_command->bind_size]];
  
  [dataController read_uint32:range lastReadHex:&lastReadHex];
  [node.details appendRow:[NSString stringWithFormat:@"%.8lX", range.location]
                         :lastReadHex
                         :@"Weak Binding Info Offset"
                         :[NSString stringWithFormat:@"%u", dyld_info_command->weak_bind_off]];
  
  [dataController read_uint32:range lastReadHex:&lastReadHex];
  [node.details appendRow:[NSString stringWithFormat:@"%.8lX", range.location]
                         :lastReadHex
                         :@"Weak Binding Info Size"
                         :[NSString stringWithFormat:@"%u", dyld_info_command->weak_bind_size]];
  
  [dataController read_uint32:range lastReadHex:&lastReadHex];
  [node.details appendRow:[NSString stringWithFormat:@"%.8lX", range.location]
                         :lastReadHex
                         :@"Lazy Binding Info Offset"
                         :[NSString stringWithFormat:@"%u", dyld_info_command->lazy_bind_off]];
  
  [dataController read_uint32:range lastReadHex:&lastReadHex];
  [node.details appendRow:[NSString stringWithFormat:@"%.8lX", range.location]
                         :lastReadHex
                         :@"Lazy Binding Info Size"
                         :[NSString stringWithFormat:@"%u", dyld_info_command->lazy_bind_size]];
  
  [dataController read_uint32:range lastReadHex:&lastReadHex];
  [node.details appendRow:[NSString stringWithFormat:@"%.8lX", range.location]
                         :lastReadHex
                         :@"Export Info Offset"
                         :[NSString stringWithFormat:@"%u", dyld_info_command->export_off]];
  
  [dataController read_uint32:range lastReadHex:&lastReadHex];
  [node.details appendRow:[NSString stringWithFormat:@"%.8lX", range.location]
                         :lastReadHex
                         :@"Export Info Size"
                         :[NSString stringWithFormat:@"%u", dyld_info_command->export_size]];
  return node;
}

//-----------------------------------------------------------------------------
- (MVNode *)createLCEncryptionInfoNode:(MVNode *)parent
                               caption:(NSString *)caption
                              location:(uint32_t)location
               encryption_info_command:(struct encryption_info_command const *)encryption_info_command
{
  MVNodeSaver nodeSaver;
  MVNode * node = [parent insertChildWithDetails:caption location:location length:encryption_info_command->cmdsize saver:nodeSaver]; 
  
  NSRange range = NSMakeRange(location,0);
  NSString * lastReadHex;
  
  [dataController read_uint32:range lastReadHex:&lastReadHex];
  [node.details appendRow:[NSString stringWithFormat:@"%.8lX", range.location]
                         :lastReadHex
                         :@"Command"
                         :[self getNameForCommand:encryption_info_command->cmd]];
  
  [node.details setAttributes:MVCellColorAttributeName,[NSColor greenColor],nil];
  
  [dataController read_uint32:range lastReadHex:&lastReadHex];
  [node.details appendRow:[NSString stringWithFormat:@"%.8lX", range.location]
                         :lastReadHex
                         :@"Command Size"
                         :[NSString stringWithFormat:@"%u", encryption_info_command->cmdsize]];
  
  [node.details setAttributes:MVCellColorAttributeName,[NSColor greenColor],
                              MVUnderlineAttributeName,@"YES",nil];
  
  [dataController read_uint32:range lastReadHex:&lastReadHex];
  [node.details appendRow:[NSString stringWithFormat:@"%.8lX", range.location]
                         :lastReadHex
                         :@"Crypt Offset"
                         :[NSString stringWithFormat:@"%u", encryption_info_command->cryptoff]];
  
  [dataController read_uint32:range lastReadHex:&lastReadHex];
  [node.details appendRow:[NSString stringWithFormat:@"%.8lX", range.location]
                         :lastReadHex
                         :@"Crypt Size"
                         :[NSString stringWithFormat:@"%u", encryption_info_command->cryptsize]];
  
  [dataController read_uint32:range lastReadHex:&lastReadHex];
  [node.details appendRow:[NSString stringWithFormat:@"%.8lX", range.location]
                         :lastReadHex
                         :@"Crypt ID"
                         :[NSString stringWithFormat:@"%u", encryption_info_command->cryptid]];
  return node;
}

//-----------------------------------------------------------------------------
- (MVNode *)createLCEncryptionInfo64Node:(MVNode *)parent
                                 caption:(NSString *)caption
                                location:(uint32_t)location
              encryption_info_command_64:(struct encryption_info_command_64 const *)encryption_info_command_64
{
  MVNodeSaver nodeSaver;
  MVNode * node = [parent insertChildWithDetails:caption location:location length:encryption_info_command_64->cmdsize saver:nodeSaver];
  
  NSRange range = NSMakeRange(location,0);
  NSString * lastReadHex;
  
  [dataController read_uint32:range lastReadHex:&lastReadHex];
  [node.details appendRow:[NSString stringWithFormat:@"%.8lX", range.location]
                         :lastReadHex
                         :@"Command"
                         :[self getNameForCommand:encryption_info_command_64->cmd]];
  
  [node.details setAttributes:MVCellColorAttributeName,[NSColor greenColor],nil];
  
  [dataController read_uint32:range lastReadHex:&lastReadHex];
  [node.details appendRow:[NSString stringWithFormat:@"%.8lX", range.location]
                         :lastReadHex
                         :@"Command Size"
                         :[NSString stringWithFormat:@"%u", encryption_info_command_64->cmdsize]];
  
  [node.details setAttributes:MVCellColorAttributeName,[NSColor greenColor],
   MVUnderlineAttributeName,@"YES",nil];
  
  [dataController read_uint32:range lastReadHex:&lastReadHex];
  [node.details appendRow:[NSString stringWithFormat:@"%.8lX", range.location]
                         :lastReadHex
                         :@"Crypt Offset"
                         :[NSString stringWithFormat:@"%u", encryption_info_command_64->cryptoff]];
  
  [dataController read_uint32:range lastReadHex:&lastReadHex];
  [node.details appendRow:[NSString stringWithFormat:@"%.8lX", range.location]
                         :lastReadHex
                         :@"Crypt Size"
                         :[NSString stringWithFormat:@"%u", encryption_info_command_64->cryptsize]];
  
  [dataController read_uint32:range lastReadHex:&lastReadHex];
  [node.details appendRow:[NSString stringWithFormat:@"%.8lX", range.location]
                         :lastReadHex
                         :@"Crypt ID"
                         :[NSString stringWithFormat:@"%u", encryption_info_command_64->cryptid]];

  [dataController read_uint32:range lastReadHex:&lastReadHex];
  [node.details appendRow:[NSString stringWithFormat:@"%.8lX", range.location]
                         :lastReadHex
                         :@"Padding"
                         :[NSString stringWithFormat:@"%u", encryption_info_command_64->pad]];
  
  return node;
}

//-----------------------------------------------------------------------------
- (MVNode *)createLCRPathNode:(MVNode *)parent
                      caption:(NSString *)caption
                     location:(uint32_t)location
                rpath_command:(struct rpath_command const *)rpath_command
{
  MVNodeSaver nodeSaver;
  MVNode * node = [parent insertChildWithDetails:caption location:location length:rpath_command->cmdsize saver:nodeSaver]; 
  
  NSRange range = NSMakeRange(location,0);
  NSString * lastReadHex;
  
  [dataController read_uint32:range lastReadHex:&lastReadHex];
  [node.details appendRow:[NSString stringWithFormat:@"%.8lX", range.location]
                         :lastReadHex
                         :@"Command"
                         :[self getNameForCommand:rpath_command->cmd]];
  
  [node.details setAttributes:MVCellColorAttributeName,[NSColor greenColor],nil];
  
  [dataController read_uint32:range lastReadHex:&lastReadHex];
  [node.details appendRow:[NSString stringWithFormat:@"%.8lX", range.location]
                         :lastReadHex
                         :@"Command Size"
                         :[NSString stringWithFormat:@"%u", rpath_command->cmdsize]];
  
  [node.details setAttributes:MVCellColorAttributeName,[NSColor greenColor],
                              MVUnderlineAttributeName,@"YES",nil];
  
  [dataController read_uint32:range lastReadHex:&lastReadHex];
  [node.details appendRow:[NSString stringWithFormat:@"%.8lX", range.location]
                         :lastReadHex
                         :@"Str Offset"
                         :[NSString stringWithFormat:@"%u", rpath_command->path.offset]];
  
  [node.details setAttributes:MVUnderlineAttributeName,@"YES",nil];
  
  range = NSMakeRange(location + rpath_command->path.offset,0);
  NSString * name = [dataController read_string:range lastReadHex:&lastReadHex];
  [node.details appendRow:[NSString stringWithFormat:@"%.8lX", range.location]
                         :lastReadHex
                         :@"Path"
                         :name];
  return node;
}               

//-----------------------------------------------------------------------------
- (MVNode *)createLCVersionMinNode:(MVNode *)parent
                           caption:(NSString *)caption
                          location:(uint32_t)location
               version_min_command:(struct version_min_command const *)version_min_command
{
  MVNodeSaver nodeSaver;
  MVNode * node = [parent insertChildWithDetails:caption location:location length:version_min_command->cmdsize saver:nodeSaver]; 
  
  NSRange range = NSMakeRange(location,0);
  NSString * lastReadHex;
  
  [dataController read_uint32:range lastReadHex:&lastReadHex];
  [node.details appendRow:[NSString stringWithFormat:@"%.8lX", range.location]
                         :lastReadHex
                         :@"Command"
                         :[self getNameForCommand:version_min_command->cmd]];
  
  [node.details setAttributes:MVCellColorAttributeName,[NSColor greenColor],nil];

  [dataController read_uint32:range lastReadHex:&lastReadHex];
  [node.details appendRow:[NSString stringWithFormat:@"%.8lX", range.location]
                         :lastReadHex
                         :@"Command Size"
                         :[NSString stringWithFormat:@"%u", version_min_command->cmdsize]];
  
  [node.details setAttributes:MVCellColorAttributeName,[NSColor greenColor],
                              MVUnderlineAttributeName,@"YES",nil];
  
  [dataController read_uint32:range lastReadHex:&lastReadHex];
  [node.details appendRow:[NSString stringWithFormat:@"%.8lX", range.location]
                         :lastReadHex
                         :@"Version"
                         :[NSString stringWithFormat:@"%u.%u.%u",  
                           (version_min_command->version >> 16),
                           ((version_min_command->version >> 8) & 0xff),
                           (version_min_command->version & 0xff)]];

  [dataController read_uint32:range lastReadHex:&lastReadHex];
  [node.details appendRow:[NSString stringWithFormat:@"%.8lX", range.location]
                         :lastReadHex
                         :@"Reserved"
                         :[NSString stringWithFormat:@"%u", version_min_command->sdk]];
  return node;
}

//-----------------------------------------------------------------------------
- (MVNode *)createLCMainNode:(MVNode *)parent
                     caption:(NSString *)caption
                    location:(uint32_t)location
          entrypoint_command:(struct entry_point_command const *)entry_point_command
{
    MVNodeSaver nodeSaver;
    MVNode * node = [parent insertChildWithDetails:caption location:location length:entry_point_command->cmdsize saver:nodeSaver];
    
    NSRange range = NSMakeRange(location,0);
    NSString * lastReadHex;
    
    [dataController read_uint32:range lastReadHex:&lastReadHex];
    [node.details appendRow:[NSString stringWithFormat:@"%.8lX", range.location]
                           :lastReadHex
                           :@"Command"
                           :[self getNameForCommand:entry_point_command->cmd]];
    
    [node.details setAttributes:MVCellColorAttributeName,[NSColor greenColor],nil];
    
    [dataController read_uint32:range lastReadHex:&lastReadHex];
    [node.details appendRow:[NSString stringWithFormat:@"%.8lX", range.location]
                           :lastReadHex
                           :@"Command Size"
                           :[NSString stringWithFormat:@"%u", entry_point_command->cmdsize]];
    
    [node.details setAttributes:MVCellColorAttributeName,[NSColor greenColor],
     MVUnderlineAttributeName,@"YES",nil];
    
    [dataController read_uint64:range lastReadHex:&lastReadHex];
    [node.details appendRow:[NSString stringWithFormat:@"%.8lX", range.location]
                           :lastReadHex
                           :@"Entry Offset"
                           :[NSString stringWithFormat:@"%qu", entry_point_command->entryoff]];

    [dataController read_uint64:range lastReadHex:&lastReadHex];
    [node.details appendRow:[NSString stringWithFormat:@"%.8lX", range.location]
                           :lastReadHex
                           :@"Stacksize"
                           :[NSString stringWithFormat:@"%qu", entry_point_command->stacksize]];
    // add an entry with entry point address
    // this is the non-aslr value since we don't its value here
    uint64_t text_vmaddr = 0;
    if ([self is64bit] == YES)
    {
        for (Segment64Vector::const_iterator cmdIter = segments_64.begin(); cmdIter != segments_64.end(); ++cmdIter)
        {
            struct segment_command_64 const *sg = (struct segment_command_64 const *)(*cmdIter);
            if (strncmp(sg->segname, "__TEXT", 16) == 0)
            {
                text_vmaddr = sg->vmaddr;
                break;
            }
        }
    }
    else
    {
        for (SegmentVector::const_iterator cmdIter = segments.begin(); cmdIter != segments.end(); ++cmdIter)
        {
            struct segment_command const *sg = (struct segment_command const *)(*cmdIter);
            if (strncmp(sg->segname, "__TEXT", 16) == 0)
            {
                text_vmaddr = sg->vmaddr;
                break;
            }
        }
    }
        
    [node.details appendRow:[NSString stringWithFormat:@"%.8x", 0]
                           :[NSString stringWithFormat:@"0x%qx", text_vmaddr + entry_point_command->entryoff]
                           :@"Entry Point"
                           :[NSString stringWithFormat:@"0x%qx", text_vmaddr + entry_point_command->entryoff]];

    return node;
}


//-----------------------------------------------------------------------------
- (MVNode *)createLCSourceVersionNode:(MVNode *)parent
                              caption:(NSString *)caption
                             location:(uint32_t)location
               source_version_command:(struct source_version_command const *)source_version_command
{
    MVNodeSaver nodeSaver;
    MVNode * node = [parent insertChildWithDetails:caption location:location length:source_version_command->cmdsize saver:nodeSaver];
    
    NSRange range = NSMakeRange(location,0);
    NSString * lastReadHex;
    
    [dataController read_uint32:range lastReadHex:&lastReadHex];
    [node.details appendRow:[NSString stringWithFormat:@"%.8lX", range.location]
                           :lastReadHex
                           :@"Command"
                           :[self getNameForCommand:source_version_command->cmd]];
    
    [node.details setAttributes:MVCellColorAttributeName,[NSColor greenColor],nil];
    
    [dataController read_uint32:range lastReadHex:&lastReadHex];
    [node.details appendRow:[NSString stringWithFormat:@"%.8lX", range.location]
                           :lastReadHex
                           :@"Command Size"
                           :[NSString stringWithFormat:@"%u", source_version_command->cmdsize]];
    
    [node.details setAttributes:MVCellColorAttributeName,[NSColor greenColor],
     MVUnderlineAttributeName,@"YES",nil];
    
    // ripped from otool source code
    uint64_t a, b, c, d, e;
    NSString *version;
	a = (source_version_command->version >> 40) & 0xffffff;
	b = (source_version_command->version >> 30) & 0x3ff;
	c = (source_version_command->version >> 20) & 0x3ff;
	d = (source_version_command->version >> 10) & 0x3ff;
	e = source_version_command->version & 0x3ff;
	if(e != 0)
        version = [NSString stringWithFormat:@"%llu.%llu.%llu.%llu.%llu\n", a, b, c, d, e];
	else if(d != 0)
        version = [NSString stringWithFormat:@"%llu.%llu.%llu.%llu\n", a, b, c, d];
	else if(c != 0)
        version = [NSString stringWithFormat:@"%llu.%llu.%llu\n", a, b, c];
	else
        version = [NSString stringWithFormat:@"%llu.%llu\n", a, b];

    [dataController read_uint64:range lastReadHex:&lastReadHex];
    [node.details appendRow:[NSString stringWithFormat:@"%.8lX", range.location]
                           :lastReadHex
                           :@"Version"
                           :version];

    return node;
}

//-----------------------------------------------------------------------------
- (MVNode *)createLCLinkerOptionNode:(MVNode *)parent
                             caption:(NSString *)caption
                            location:(uint32_t)location
               linker_option_command:(struct linker_option_command const *)linker_option_command
{
  MVNodeSaver nodeSaver;
  MVNode * node = [parent insertChildWithDetails:caption location:location length:linker_option_command->cmdsize saver:nodeSaver];
  
  NSRange range = NSMakeRange(location,0);
  NSString * lastReadHex;
  
  [dataController read_uint32:range lastReadHex:&lastReadHex];
  [node.details appendRow:[NSString stringWithFormat:@"%.8lX", range.location]
                         :lastReadHex
                         :@"Command"
                         :[self getNameForCommand:linker_option_command->cmd]];
  
  [node.details setAttributes:MVCellColorAttributeName,[NSColor greenColor],nil];
  
  [dataController read_uint32:range lastReadHex:&lastReadHex];
  [node.details appendRow:[NSString stringWithFormat:@"%.8lX", range.location]
                         :lastReadHex
                         :@"Command Size"
                         :[NSString stringWithFormat:@"%u", linker_option_command->cmdsize]];
  
  [node.details setAttributes:MVCellColorAttributeName,[NSColor greenColor],
   MVUnderlineAttributeName,@"YES",nil];
  
#pragma message "TODO"
//  void
//  print_linker_option_command(
//                              struct linker_option_command *lo,
//                              struct load_command *lc)
//  {
//    int left, len, i;
//    char *string;
//    
//    printf("     cmd LC_LINKER_OPTION\n");
//    printf(" cmdsize %u", lo->cmdsize);
//    if(lo->cmdsize < sizeof(struct linker_option_command))
//	    printf(" Incorrect size\n");
//    else
//	    printf("\n");
//    printf("   count %u\n", lo->count);
//    string = (char *)lc + sizeof(struct linker_option_command);
//    left = lo->cmdsize - sizeof(struct linker_option_command);
//    i = 0;
//    while(left > 0){
//	    while(*string == '\0' && left > 0){
//        string++;
//        left--;
//	    }
//	    if(left > 0){
//        i++;
//        printf("  string #%d %.*s\n", i, left, string);
//        len = strnlen(string, left) + 1;
//        string += len;
//        left -= len;
//	    }
//    }
//    if(lo->count != i)
//      printf("   count %u does not match number of strings %u\n",
//             lo->count, i);
//  }
  
  return node;
}

//-----------------------------------------------------------------------------
-(MVNode *)createLoadCommandNode:(MVNode *)parent
                         caption:(NSString *)caption
                        location:(uint32_t)location
                          length:(uint32_t)length
                         command:(uint32_t)command
{
  MVNode * node = nil;
  
  switch (command)
  {
    case LC_SEGMENT:
    {
      MATCH_STRUCT(segment_command,location)
      node = [self createLCSegmentNode:parent 
                               caption:[NSString stringWithFormat:@"%@ (%s)", 
                                        caption, string(segment_command->segname,16).c_str()]
                              location:location
                       segment_command:segment_command];
      
      // preserv segment RVA/size for offset lookup
      segmentInfo[segment_command->fileoff + imageOffset] = make_pair(segment_command->vmaddr, segment_command->vmsize);
      
      // preserv load segment command info for latter use
      segments.push_back(segment_command);
      
      // Section Headers
      for (uint32_t nsect = 0; nsect < segment_command->nsects; ++nsect)
      {
        uint32_t sectionloc = location + sizeof(struct segment_command) + nsect * sizeof(struct section);
        MATCH_STRUCT(section,sectionloc)
        [self createSectionNode:node 
                        caption:[NSString stringWithFormat:@"Section Header (%s)",
                                 string(section->sectname,16).c_str()]
                       location:sectionloc
                        section:section];
        
        // preserv section fileOffset/sectName for RVA lookup
        NSDictionary * userInfo = [self userInfoForSection:section];
        sectionInfo[section->addr] = make_pair(section->offset + imageOffset, userInfo);
        
        // preserv header info for latter use
        sections.push_back(section);
      }
    } break;
      
    case LC_SEGMENT_64:
    {
      MATCH_STRUCT(segment_command_64,location)
      
      node = [self createLCSegment64Node:parent 
                                 caption:[NSString stringWithFormat:@"%@ (%s)", 
                                          caption, string(segment_command_64->segname,16).c_str()]
                                location:location
                      segment_command_64:segment_command_64];
      
      // preserv segment RVA/size for offset lookup
      segmentInfo[segment_command_64->fileoff + imageOffset] = make_pair(segment_command_64->vmaddr, segment_command_64->vmsize);
      
      // preserv load segment command info for latter use
      segments_64.push_back(segment_command_64);

      // Section Headers
      for (uint32_t nsect = 0; nsect < segment_command_64->nsects; ++nsect)
      {
        uint32_t sectionloc = location + sizeof(struct segment_command_64) + nsect * sizeof(struct section_64);
        MATCH_STRUCT(section_64,sectionloc)
        [self createSection64Node:node 
                          caption:[NSString stringWithFormat:@"Section64 Header (%s)",
                                   string(section_64->sectname,16).c_str()]
                         location:sectionloc
                       section_64:section_64];
        
        // preserv section fileOffset/sectName for RVA lookup
        NSDictionary * userInfo = [self userInfoForSection64:section_64];
        sectionInfo[section_64->addr] = make_pair(section_64->offset + imageOffset, userInfo);

        // preserv header info for latter use
        sections_64.push_back(section_64);
      }
    } break;
      
    case LC_SYMTAB:
    {
      MATCH_STRUCT(symtab_command,location)
      
      node = [self createLCSymtabNode:parent 
                              caption:caption
                             location:location
                       symtab_command:symtab_command];
      
      strtab = (char *)((uint8_t *)[dataController.fileData bytes] + imageOffset + symtab_command->stroff);
      
      for (uint32_t nsym = 0; nsym < symtab_command->nsyms; ++nsym)
      {
        if ([self is64bit] == NO)
        {
          MATCH_STRUCT(nlist,imageOffset + symtab_command->symoff + nsym * sizeof(struct nlist))
          symbols.push_back (nlist);
        }
        else // 64bit
        {
          MATCH_STRUCT(nlist_64,imageOffset + symtab_command->symoff + nsym * sizeof(struct nlist_64))
          symbols_64.push_back (nlist_64);
        }
        
      }
    } break;
      
    case LC_DYSYMTAB:
    {
      MATCH_STRUCT(dysymtab_command,location)
      node = [self createLCDysymtabNode:parent 
                                caption:caption
                               location:location
                       dysymtab_command:dysymtab_command];
    } break;
      
    case LC_TWOLEVEL_HINTS:
    {
      MATCH_STRUCT(twolevel_hints_command,location)
      node = [self createLCTwolevelHintsNode:parent 
                                     caption:caption
                                    location:location
                      twolevel_hints_command:twolevel_hints_command];
    } break;
      
    case LC_ID_DYLINKER:
    case LC_LOAD_DYLINKER:
    case LC_DYLD_ENVIRONMENT:
    {
      MATCH_STRUCT(dylinker_command,location)
      node = [self createLCDylinkerNode:parent 
                                caption:caption
                               location:location
                       dylinker_command:dylinker_command];
    } break;
    
    case LC_PREBIND_CKSUM:
    {
      MATCH_STRUCT(prebind_cksum_command,location)
      node = [self createLCPrebindChksumNode:parent 
                                     caption:caption
                                    location:location
                       prebind_cksum_command:prebind_cksum_command];
    } break;
    
    case LC_UUID:
    {
      MATCH_STRUCT(uuid_command,location)
      node = [self createLCUUIDNode:parent 
                            caption:caption
                           location:location
                       uuid_command:uuid_command];
    } break;
      
    case LC_THREAD:
    case LC_UNIXTHREAD:
    {
      MATCH_STRUCT(thread_command,location)
      node = [self createLCThreadNode:parent 
                              caption:caption
                             location:location
                       thread_command:thread_command];
    } break; 
      
    case LC_ID_DYLIB:
    case LC_LOAD_DYLIB:
    case LC_LOAD_WEAK_DYLIB:
    case LC_REEXPORT_DYLIB:
    case LC_LAZY_LOAD_DYLIB:
    case LC_LOAD_UPWARD_DYLIB:
    {
      MATCH_STRUCT(dylib_command,location)
      if (command != LC_ID_DYLIB)
      {
        dylibs.push_back (&dylib_command->dylib);
      }
      NSRange range = NSMakeRange(location + dylib_command->dylib.name.offset,0);
      NSString * name = [dataController read_string:range];
      
      node = [self createLCDylibNode:parent 
                             caption:[NSString stringWithFormat:@"%@ (%@)", 
                                      caption, [name lastPathComponent]]
                            location:location
                       dylib_command:dylib_command];
    } break; 
      
    case LC_CODE_SIGNATURE:
    case LC_SEGMENT_SPLIT_INFO:
    case LC_FUNCTION_STARTS:
    case LC_DATA_IN_CODE:
    case LC_DYLIB_CODE_SIGN_DRS:
    case LC_LINKER_OPTIMIZATION_HINT:
    {
      MATCH_STRUCT(linkedit_data_command,location)
      node = [self createLCLinkeditDataNode:parent 
                                    caption:caption
                                   location:location
                      linkedit_data_command:linkedit_data_command];
    } break;   

    case LC_ENCRYPTION_INFO:
    {
      MATCH_STRUCT(encryption_info_command, location)
      node = [self createLCEncryptionInfoNode:parent
                                      caption:caption
                                     location:location
                      encryption_info_command:encryption_info_command];
    } break;
      
    case LC_ENCRYPTION_INFO_64:
    {
      MATCH_STRUCT(encryption_info_command_64, location)
      node = [self createLCEncryptionInfo64Node:parent
                                        caption:caption
                                       location:location
                     encryption_info_command_64:encryption_info_command_64];
    } break;

    case LC_RPATH:
    {
      MATCH_STRUCT(rpath_command, location)
      node = [self createLCRPathNode:parent
                             caption:caption
                            location:location
                       rpath_command:rpath_command];
    } break;
    
    case LC_ROUTINES:
    {
      MATCH_STRUCT(routines_command,location)
      node = [self createLCRoutinesNode:parent 
                                caption:caption
                               location:location
                       routines_command:routines_command];
    } break; 
      
    case LC_ROUTINES_64:
    {
      MATCH_STRUCT(routines_command_64,location)
      node = [self createLCRoutines64Node:parent 
                                  caption:caption
                                 location:location
                      routines_command_64:routines_command_64];
    } break;   
      
    case LC_SUB_FRAMEWORK:
    {
      MATCH_STRUCT(sub_framework_command,location)
      node = [self createLCSubFrameworkNode:parent 
                                    caption:caption
                                   location:location
                      sub_framework_command:sub_framework_command];
    } break; 
      
    case LC_SUB_UMBRELLA:
    {
      MATCH_STRUCT(sub_umbrella_command,location)
      node = [self createLCSubUmbrellaNode:parent 
                                   caption:caption
                                  location:location
                      sub_umbrella_command:sub_umbrella_command];
    } break; 
      
    case LC_SUB_CLIENT:
    {
      MATCH_STRUCT(sub_client_command,location)
      node = [self createLCSubClientNode:parent 
                                 caption:caption
                                location:location
                      sub_client_command:sub_client_command];
    } break; 
      
    case LC_SUB_LIBRARY:
    {
      MATCH_STRUCT(sub_library_command,location)
      node = [self createLCSubLibraryNode:parent 
                                  caption:caption
                                 location:location
                      sub_library_command:sub_library_command];
    } break; 
      
    case LC_DYLD_INFO:
    case LC_DYLD_INFO_ONLY:
    {
      MATCH_STRUCT(dyld_info_command,location)
      node = [self createLCDyldInfoNode:parent 
                                caption:caption
                               location:location
                      dyld_info_command:dyld_info_command];
    } break;   
    
    case LC_VERSION_MIN_MACOSX:
    case LC_VERSION_MIN_IPHONEOS:
    {
      MATCH_STRUCT(version_min_command,location)
      node = [self createLCVersionMinNode:parent 
                                  caption:caption
                                 location:location
                      version_min_command:version_min_command];
      
    } break;
    case LC_MAIN:
    {
        MATCH_STRUCT(entry_point_command, location)
        node = [self createLCMainNode:parent
                              caption:caption
                             location:location
                   entrypoint_command:entry_point_command];
    } break;
    case LC_SOURCE_VERSION:
    {
        MATCH_STRUCT(source_version_command, location);
        node = [self createLCSourceVersionNode:parent
                                       caption:caption
                                      location:location
                        source_version_command:source_version_command];
    } break;
    case LC_LINKER_OPTION:
    {
      MATCH_STRUCT(linker_option_command, location);
      node = [self createLCLinkerOptionNode:parent
                                    caption:caption
                                   location:location
                      linker_option_command:linker_option_command];
    } break;
    default:
      [self createDataNode:parent 
                   caption:[NSString stringWithFormat:@"%@ (unsupported)", caption]
                  location:location
                    length:length];
  } // switch
  
  return node;
}

@end
