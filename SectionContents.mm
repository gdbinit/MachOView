/*
 *  SectionContents.mm
 *  MachOView
 *
 *  Created by psaghelyi on 15/09/2010.
 *
 */

#include <string>
#include <vector>
#include <set>
#include <map>

#import "Common.h"
#import "SectionContents.h"
#import "CRTFootPrints.h"
#import "ReadWrite.h"
#import "DataController.h"
#import "capstone.h"

#define TAB_WIDTH 10

using namespace std;

//============================================================================
@implementation MachOLayout (SectionContents)

//-----------------------------------------------------------------------------
- (MVNode *)createPointersNode:(MVNode *)parent
                       caption:(NSString *)caption
                      location:(uint32_t)location
                        length:(uint32_t)length
{
  MVNodeSaver nodeSaver;
  MVNode * node = [parent insertChildWithDetails:caption location:location length:length saver:nodeSaver]; 
  
  NSRange range = NSMakeRange(location,0);
  NSString * lastReadHex;

  while (NSMaxRange(range) < location + length)
  {
    uint32_t ptr = [dataController read_uint32:range lastReadHex:&lastReadHex];
    NSString * symbolName = [NSString stringWithFormat:@"%@->%@",
                             [self findSymbolAtRVA:[self fileOffsetToRVA:range.location]],
                             [self findSymbolAtRVA:ptr]];
    
    [node.details appendRow:[NSString stringWithFormat:@"%.8lX", range.location]
                           :lastReadHex
                           :@"Pointer"
                           :symbolName];
    
    [node.details setAttributes:MVMetaDataAttributeName,symbolName,nil];
    
    [symbolNames setObject:symbolName 
                    forKey:[NSNumber numberWithUnsignedLong:[self fileOffsetToRVA:range.location]]];
  }
  
  return node;
}

//-----------------------------------------------------------------------------
- (MVNode *)createPointers64Node:(MVNode *)parent
                         caption:(NSString *)caption
                        location:(uint32_t)location
                          length:(uint32_t)length
{
  MVNodeSaver nodeSaver;
  MVNode * node = [parent insertChildWithDetails:caption location:location length:length saver:nodeSaver]; 
  
  NSRange range = NSMakeRange(location,0);
  NSString * lastReadHex;

  while (NSMaxRange(range) < location + length)
  {
    uint64_t ptr = [dataController read_uint64:range lastReadHex:&lastReadHex];
    NSString * symbolName = [NSString stringWithFormat:@"%@->%@",
                             [self findSymbolAtRVA64:[self fileOffsetToRVA64:range.location]],
                             [self findSymbolAtRVA64:ptr]];
    
    [node.details appendRow:[NSString stringWithFormat:@"%.8lX", range.location]
                           :lastReadHex
                           :@"Pointer"
                           :symbolName];
    
    [node.details setAttributes:MVMetaDataAttributeName,symbolName,nil];
    
    [symbolNames setObject:symbolName 
                    forKey:[NSNumber numberWithUnsignedLongLong:[self fileOffsetToRVA64:range.location]]];
  }
  
  return node;
}

//-----------------------------------------------------------------------------
-(MVNode *)createCStringsNode:(MVNode *)parent
                      caption:(NSString *)caption
                     location:(uint32_t)location
                       length:(uint32_t)length
{
  MVNodeSaver nodeSaver;
  MVNode * node = [parent insertChildWithDetails:caption location:location length:length saver:nodeSaver]; 
  
  NSRange range = NSMakeRange(location,0);
  NSString * lastReadHex;

  while (NSMaxRange(range) < location + length)
  {
    NSString * symbolName = [dataController read_string:range lastReadHex:&lastReadHex];
    
    [node.details appendRow:[NSString stringWithFormat:@"%.8lX", range.location]
                           :lastReadHex
                           :[NSString stringWithFormat:@"CString (length:%lu)", [symbolName length]]
                           :symbolName];
    
    [node.details setAttributes:MVMetaDataAttributeName,symbolName,nil];
    
    // fill in lookup table with C Strings
    if ([self is64bit] == NO)
    {
      uint32_t rva = [self fileOffsetToRVA:range.location];
      [symbolNames setObject:[NSString stringWithFormat:@"0x%X:\"%@\"", rva, symbolName]
                      forKey:[NSNumber numberWithUnsignedLong:rva]];
    }
    else
    {
      uint64_t rva64 = [self fileOffsetToRVA64:range.location];
      [symbolNames setObject:[NSString stringWithFormat:@"0x%qX:\"%@\"", rva64, symbolName]
                      forKey:[NSNumber numberWithUnsignedLongLong:rva64]];
    }
  }
  
  return node;
}

//-----------------------------------------------------------------------------
-(MVNode *)createLiteralsNode:(MVNode *)parent
                      caption:(NSString *)caption
                     location:(uint32_t)location
                       length:(uint32_t)length
                       stride:(uint32_t)stride
{
  MVNodeSaver nodeSaver;
  MVNode * node = [parent insertChildWithDetails:caption location:location length:length saver:nodeSaver]; 
  
  NSRange range = NSMakeRange(location,0);
  NSString * lastReadHex;

  while (NSMaxRange(range) < location + length)
  {
    NSData * data = [dataController read_bytes:range length:stride lastReadHex:&lastReadHex];

    NSString * literalStr;
    switch (stride)
    {
      case sizeof(float): 
      {
        double num = *(float *)[data bytes];
        literalStr = [NSString stringWithFormat:@"%.16g", num];
      } break;
      
      case sizeof(double): 
      {
        double num = *(double *)[data bytes]; 
        literalStr = [NSString stringWithFormat:@"%.16g", num];
      } break;
        
      default:
      case sizeof(long double): 
      {
        long double num = *(long double *)[data bytes]; 
        literalStr = [NSString stringWithFormat:@"%.16Lg", num];
      } break;
    }
    
    [node.details appendRow:[NSString stringWithFormat:@"%.8lX", range.location]
                           :lastReadHex
                           :@"Floating Point Number"
                           :literalStr];
    
    // fill in lookup table with string literals
    if ([self is64bit] == NO)
    {
      uint32_t rva = [self fileOffsetToRVA:range.location];
      [symbolNames setObject:[NSString stringWithFormat:@"0x%X:%@f", rva, literalStr]
                      forKey:[NSNumber numberWithUnsignedLong:rva]]; 
    }
    else
    {
      uint64_t rva64 = [self fileOffsetToRVA64:range.location];
      [symbolNames setObject:[NSString stringWithFormat:@"0x%qX:%@f", rva64, literalStr]
                      forKey:[NSNumber numberWithUnsignedLongLong:rva64]]; 
    }
  }
  return node;
  
}

//-----------------------------------------------------------------------------
- (MVNode *)createIndPointersNode:(MVNode *)parent
                          caption:(NSString *)caption
                         location:(uint32_t)location
                           length:(uint32_t)length
{
  MVNodeSaver nodeSaver;
  MVNode * node = [parent insertChildWithDetails:caption location:location length:length saver:nodeSaver]; 
  
  NSRange range = NSMakeRange(location,0);
  NSString * lastReadHex;

  while (NSMaxRange(range) < location + length)
  {
    [dataController read_uint32:range lastReadHex:&lastReadHex];
    NSString * symbolName = [self findSymbolAtRVA:[self fileOffsetToRVA:range.location]];
    [node.details appendRow:[NSString stringWithFormat:@"%.8lX", range.location]
                           :lastReadHex
                           :@"Indirect Pointer"
                           :symbolName];
    
    [node.details setAttributes:MVMetaDataAttributeName,symbolName,nil];
  }
  
  return node;
}

//-----------------------------------------------------------------------------
- (MVNode *)createIndPointers64Node:(MVNode *)parent
                            caption:(NSString *)caption
                           location:(uint32_t)location
                             length:(uint32_t)length
{
  MVNodeSaver nodeSaver;
  MVNode * node = [parent insertChildWithDetails:caption location:location length:length saver:nodeSaver]; 
  
  NSRange range = NSMakeRange(location,0);
  NSString * lastReadHex;

  while (NSMaxRange(range) < location + length)
  {
    [dataController read_uint64:range lastReadHex:&lastReadHex];
    NSString * symbolName = [self findSymbolAtRVA64:[self fileOffsetToRVA64:range.location]];
    [node.details appendRow:[NSString stringWithFormat:@"%.8lX", range.location]
                           :lastReadHex
                           :@"Indirect Pointer"
                           :symbolName];
    
    [node.details setAttributes:MVMetaDataAttributeName,symbolName,nil];
  }
  
  return node;
}

//-----------------------------------------------------------------------------
- (MVNode *)createIndStubsNode:(MVNode *)parent
                       caption:(NSString *)caption
                      location:(uint32_t)location
                        length:(uint32_t)length
                        stride:(uint32_t)stride
{
  MVNodeSaver nodeSaver;
  MVNode * node = [parent insertChildWithDetails:caption location:location length:length saver:nodeSaver]; 
  
  NSRange range = NSMakeRange(location,0);
  NSString * lastReadHex;

  while (NSMaxRange(range) < location + length)
  {
    [dataController read_bytes:range length:stride lastReadHex:&lastReadHex];
    NSString * symbolName = [self findSymbolAtRVA:[self fileOffsetToRVA:range.location]];
    [node.details appendRow:[NSString stringWithFormat:@"%.8lX", range.location]
                           :lastReadHex
                           :@"Indirect Stub"
                           :symbolName];
    
    [node.details setAttributes:MVMetaDataAttributeName,symbolName,nil];
  }
  
  return node;
}

//-----------------------------------------------------------------------------
- (MVNode *)createIndStubs64Node:(MVNode *)parent
                         caption:(NSString *)caption
                        location:(uint32_t)location
                          length:(uint32_t)length
                          stride:(uint32_t)stride
{
  MVNodeSaver nodeSaver;
  MVNode * node = [parent insertChildWithDetails:caption location:location length:length saver:nodeSaver]; 
  
  NSRange range = NSMakeRange(location,0);
  NSString * lastReadHex;

  while (NSMaxRange(range) < location + length)
  {
    [dataController read_bytes:range length:stride lastReadHex:&lastReadHex];
    NSString * symbolName = [self findSymbolAtRVA64:[self fileOffsetToRVA64:range.location]];
    [node.details appendRow:[NSString stringWithFormat:@"%.8lX", range.location]
                           :lastReadHex
                           :@"Indirect Stub"
                           :symbolName];
    
    [node.details setAttributes:MVMetaDataAttributeName,symbolName,nil];
  }
  
  return node;
}


//============================= X86 =========================
//===========================================================
static AsmFootPrint const classicStubHelperX86 =
{
	{1, 0x68}, GAP(4),                        // pushl   $foo$lazy_ptr
	{1, 0xE9}, GAP(4),                        // jmp     helperhelper
};

static AsmFootPrint const hybridStubHelperX86 =
{
  {1, 0x68}, GAP(4),                        // pushl   $lazy-info-offset
	{1, 0x68}, GAP(4),                        // pushl   $foo$lazy_ptr
	{1, 0xE9}, GAP(4),                        // jmp     dyld_hybrid_stub_binding_helper
	{1, 0x90},                                // nop
};

static AsmFootPrint const hybridStubHelperHelperX86 =
{
  {2, 0x83, 0x3D}, GAP(4), {1, 0x00},       // cmpl    $0x00,_fast_lazy_bind
	{2, 0x75,	0x0D},                          // jne     $0x0D
	{4, 0x89,	0x44, 0x24, 0x04},              // movl    %eax,4(%esp)
	{1, 0x58},                                // popl    %eax
	{3, 0x87, 0x04, 0x24},                    // xchgl   (%esp),%eax
	{1, 0xE9}, GAP(4),                        // jmpl    dyld_stub_binding_helper
	{3, 0x83, 0xC4, 0x04},                    // addl    $0x04,%esp
	{1, 0x68}, GAP(4),                        // pushl   imageloadercache
	{2, 0xFF, 0x25}, GAP(4),                  // jmp     *_fast_lazy_bind(%rip)
};

static AsmFootPrint const fastStubHelperX86 =
{
  {1, 0x68}, GAP(4),                        // pushl   $lazy-info-offset
  {1, 0xE9}, GAP(4),                        // jmp     helperhelper
};

static AsmFootPrint const fastStubHelperHelperX86 =
{
	{1, 0x68}, GAP(4),                        // pushl   imageloadercache
	{2, 0xFF, 0x25}, GAP(4),                  // jmp     *_fast_lazy_bind
	{1, 0x90},                                // nop
};

//=========================== X86_64 ========================
//===========================================================

static AsmFootPrint const classicStubHelperX86_64 =
{
  {3, 0x4C,	0x8D, 0x1D}, GAP(4),            // lea    foo$lazy_ptr(%rip),%r11
	{1, 0xE9}, GAP(4),                        // jmp    dyld_stub_binding_helper
};


static AsmFootPrint const hybridStubHelperX86_64 =
{
  {1, 0x68}, GAP(4),                        // pushq  $lazy-info-offset
	{3, 0x4C, 0x8D, 0x1D}, GAP(4),            // lea    foo$lazy_ptr(%rip),%r11
	{1, 0xE9}, GAP(4),                        // jmp    helper-helper
	{1, 0x90},                                // nop
};

static AsmFootPrint const hybridStubHelperHelperX86_64 =
{
  {3, 0x48, 0x83, 0x3D}, GAP(4), {1, 0x00}, // cmpq   $0x00,_fast_lazy_bind
	{2, 0x74,	0x0F},                          // je     $0x0F
	{3, 0x4C, 0x8D,	0x1D}, GAP(4),            // leaq   imageCache(%rip),%r11
	{2, 0x41,	0x53},                          // pushq  %r11
	{2, 0xFF,	0x25}, GAP(4),                  // jmp    *_fast_lazy_bind(%rip)
	{4, 0x48, 0x83, 0xC4, 0x08},              // addq   $8,%rsp
	{1, 0xE9}, GAP(4),                        // jmp    dyld_stub_binding_helper
};


static AsmFootPrint const fastStubHelperX86_64 =
{
  {1, 0x68}, GAP(4),                        // pushq  $lazy-info-offset
	{1, 0xE9}, GAP(4),                        // jmp    helperhelper
};

static AsmFootPrint const fastStubHelperHelperX86_64 =
{
  {3, 0x4C, 0x8D, 0x1D}, GAP(4),            // leaq   dyld_mageLoaderCache(%rip),%r11
  {2, 0x41, 0x53},                          // pushq  %r11
  {2, 0xFF, 0x25}, GAP(4),                  // jmp    *_fast_lazy_bind(%rip)
  {1, 0x90},                                // nop
};

//=========================== ARM ===========================
//===========================================================
static AsmFootPrint const fastStubHelperARM =
{
  {4, 0xe5, 0x9f, 0xc0, 0x00},              // ldr  ip, [pc, #0]
	{4, 0xea, 0x00, 0x00, 0x00},              // b	_helperhelper
  GAP(4),                                   // lazy binding info
};

static AsmFootPrint const fastStubHelperHelperARM =
{
  // push lazy-info-offset
  {4, 0xe5, 0x2d, 0xc0, 0x04},              // str ip, [sp, #-4]!
  // push address of dyld_mageLoaderCache
  {4, 0xe5, 0x9f, 0xc0, 0x10},              // ldr	ip, L1
  {4, 0xe0, 0x8f, 0xc0, 0x0c},              // add	ip, pc, ip
  {4, 0xe5, 0x2d, 0xc0, 0x04},              // str ip, [sp, #-4]!
  // jump through _fast_lazy_bind
  {4, 0xe5, 0x9f, 0xc0, 0x08},              // ldr	ip, L2
  {4, 0xe0, 0x8f, 0xc0, 0x0c},              // add	ip, pc, ip
  {4, 0xe5, 0x9c, 0xf0, 0x00},              // ldr	pc, [ip]
  GAP(4),                                   // L1: .long fFastStubGOTAtom - (helperhelper+16)
  GAP(4),                                   // L2: .long _fast_lazy_bind - (helperhelper+28)
};


//-----------------------------------------------------------------------------
// __stub_helper:
//
//  StubHelperHelper
//  StubHelper
//  StubHelper
//  ...

// __symbol_stub1:
//  FF 25 <relative to indirect>
//  ...
//-----------------------------------------------------------------------------
- (MVNode *)createStubHelperNode:(MVNode *)parent
                         caption:(NSString *)caption
                        location:(uint32_t)location
                          length:(uint32_t)length
{
  MVNodeSaver nodeSaver;
  MVNode * node = [parent insertChildWithDetails:caption location:location length:length saver:nodeSaver]; 
  
  NSRange range = NSMakeRange(location,0);
  NSString * lastReadHex;
  
  NSData * data;
  uint32_t address;

  if ([self matchAsmAtOffset:range.location 
                asmFootPrint:hybridStubHelperHelperX86 
                   lineCount:sizeof(hybridStubHelperHelperX86)/FOOTPRINT_STRIDE])
  {
    data = [dataController read_bytes:range length:7 lastReadHex:&lastReadHex];
    address = *(uint32_t *)((uint8_t *)data.bytes + 2);
    [node.details appendRow:[NSString stringWithFormat:@"%.8lX", range.location]
                           :lastReadHex
                           :@"cmpl  $0x00,_fast_lazy_bind"
                           :[self findSymbolAtRVA:address]];

    [dataController read_bytes:range length:2 lastReadHex:&lastReadHex];
    [node.details appendRow:[NSString stringWithFormat:@"%.8lX", range.location]
                           :lastReadHex
                           :@"jne  $0x0D"
                           :@""];

    [dataController read_bytes:range length:4 lastReadHex:&lastReadHex];
    [node.details appendRow:[NSString stringWithFormat:@"%.8lX", range.location]
                           :lastReadHex
                           :@"movl  %eax,4(%esp)"
                           :@""];

    [dataController read_bytes:range length:1 lastReadHex:&lastReadHex];
    [node.details appendRow:[NSString stringWithFormat:@"%.8lX", range.location]
                           :lastReadHex
                           :@"popl  %eax"
                           :@""];

    [dataController read_bytes:range length:3 lastReadHex:&lastReadHex];
    [node.details appendRow:[NSString stringWithFormat:@"%.8lX", range.location]
                           :lastReadHex
                           :@"xchgl  (%esp),%eax"
                           :@""];

    data = [dataController read_bytes:range length:5 lastReadHex:&lastReadHex];
    address = [self fileOffsetToRVA:NSMaxRange(range) + *(uint32_t *)((uint8_t *)data.bytes + 1)];
    [node.details appendRow:[NSString stringWithFormat:@"%.8lX", range.location]
                           :lastReadHex
                           :@"jmpl  dyld_stub_binding_helper"
                           :[self findSymbolAtRVA:address]];

    [dataController read_bytes:range length:3 lastReadHex:&lastReadHex];
    [node.details appendRow:[NSString stringWithFormat:@"%.8lX", range.location]
                           :lastReadHex
                           :@"addl  $0x04,%esp"
                           :@""];

    data = [dataController read_bytes:range length:5 lastReadHex:&lastReadHex];
    address = *(uint32_t *)((uint8_t *)data.bytes + 1);
    [node.details appendRow:[NSString stringWithFormat:@"%.8lX", range.location]
                           :lastReadHex
                           :@"pushl  imageloadercache"
                           :[self findSymbolAtRVA:address]];

    data = [dataController read_bytes:range length:6 lastReadHex:&lastReadHex];
    address = *(uint32_t *)((uint8_t *)data.bytes + 2);
    [node.details appendRow:[NSString stringWithFormat:@"%.8lX", range.location]
                           :lastReadHex
                           :@"jmp  *_fast_lazy_bind(%rip)"
                           :[self findSymbolAtRVA:address]];
    
    [node.details setAttributes:MVUnderlineAttributeName,@"YES",nil];
    
  }
  else if ([self matchAsmAtOffset:range.location 
                     asmFootPrint:fastStubHelperHelperX86 
                        lineCount:sizeof(fastStubHelperHelperX86)/FOOTPRINT_STRIDE])
  {
    data = [dataController read_bytes:range length:5 lastReadHex:&lastReadHex];
    address = *(uint32_t *)((uint8_t *)data.bytes + 1);
    [node.details appendRow:[NSString stringWithFormat:@"%.8lX", range.location]
                           :lastReadHex
                           :@"pushl  imageloadercache"
                           :[self findSymbolAtRVA:address]];
    
    data = [dataController read_bytes:range length:6 lastReadHex:&lastReadHex];
    address = *(uint32_t *)((uint8_t *)data.bytes + 2);
    [node.details appendRow:[NSString stringWithFormat:@"%.8lX", range.location]
                           :lastReadHex
                           :@"jmp  *_fast_lazy_bind"
                           :[self findSymbolAtRVA:address]];

    [dataController read_bytes:range length:1 lastReadHex:&lastReadHex];
    [node.details appendRow:[NSString stringWithFormat:@"%.8lX", range.location]
                           :lastReadHex
                           :@"nop"
                           :@""];
    
    [node.details setAttributes:MVUnderlineAttributeName,@"YES",nil];
    
  }
  
  return node;
}


//-----------------------------------------------------------------------------
- (MVNode *)createTextNode:(MVNode *)parent
                   caption:(NSString *)caption
                  location:(uint32_t)location
                    length:(uint32_t)length
                    reloff:(uint32_t)reloff
                    nreloc:(uint32_t)nreloc
                 extreloff:(uint32_t)extreloff
                   nextrel:(uint32_t)nextrel
                 locreloff:(uint32_t)locreloff
                   nlocrel:(uint32_t)nlocrel
{
    MVNodeSaver nodeSaver;
    MVNode * node = [parent insertChildWithDetails:caption location:location length:length saver:nodeSaver];
    
    // accumulate search info
    NSUInteger bookmark = node.details.rowCount;
    NSString * symbolName = nil;
    
    if (length == 0) // prevent from attempting to parse zero length sections
    {
        return node;
    }
    
    // prepare disassembler params
    //===========================================================================
    MATCH_STRUCT(mach_header,imageOffset);
    
    char *                    ot_sect = (char*)[dataController.fileData bytes] + location;
    uint32_t                  ot_left = length;
    uint64_t                  ot_addr = ([self is64bit] == NO ? [self fileOffsetToRVA:location] : [self fileOffsetToRVA64:location]);
    
    csh cs_handle = 0;
    cs_insn *cs_insn = NULL;
    size_t disasm_count = 0;
    cs_err cserr;
    /* open capstone */
    cs_arch target_arch;
    cs_mode target_mode;
    switch (mach_header->cputype)
    {
        case CPU_TYPE_I386:
            target_arch = CS_ARCH_X86;
            target_mode = CS_MODE_32;
            break;
        case CPU_TYPE_X86_64:
            target_arch = CS_ARCH_X86;
            target_mode = CS_MODE_64;
            break;
        case CPU_TYPE_ARM:
            target_arch = CS_ARCH_ARM;
            target_mode = CS_MODE_ARM;
            break;
        case CPU_TYPE_ARM64:
            target_arch = CS_ARCH_ARM64;
            target_mode = CS_MODE_ARM;
            break;
        default:
            NSLog(@"NO CPU FOUND!");
            break;
    }
    
    if ( (cserr = cs_open(target_arch, target_mode, &cs_handle)) != CS_ERR_OK )
    {
        NSLog(@"Failed to initialize Capstone: %d, %s.", cserr, cs_strerror(cs_errno(cs_handle)));
        return node;
    }
    
    /* set or not thumb mode for 32 bits ARM targets */
    if (mach_header->cputype == CPU_TYPE_ARM)
    {
        switch (mach_header->cpusubtype)
        {
            case CPU_SUBTYPE_ARM_V7:
            case CPU_SUBTYPE_ARM_V7F:
            case CPU_SUBTYPE_ARM_V7S:
            case CPU_SUBTYPE_ARM_V7K:
            case CPU_SUBTYPE_ARM_V8:
                cs_option(cs_handle, CS_OPT_MODE, CS_MODE_THUMB);
                break;
            default:
                cs_option(cs_handle, CS_OPT_MODE, CS_MODE_ARM);
                break;
        }
    }
    
    /* enable detail - we need fields available in detail field */
    cs_option(cs_handle, CS_OPT_DETAIL, CS_OPT_ON);
    cs_option(cs_handle, CS_OPT_SKIPDATA, CS_OPT_ON);
    
    /* disassemble the whole section */
    /* this will fail if we have data in code or jump tables because Capstone stops when it can't disassemble */
    /* a bit of a problem with most binaries :( */
    /* XXX: parse data in code section to partially solve this */
    disasm_count = cs_disasm(cs_handle, (const uint8_t *)ot_sect, ot_left, ot_addr, 0, &cs_insn);
    NSLog(@"Disassembled %lu instructions.", disasm_count);
    uint32_t fileOffset = ([self is64bit] == NO ? [self RVAToFileOffset:(uint32_t)ot_addr] : [self RVA64ToFileOffset:ot_addr]);
    for (size_t i = 0; i < disasm_count; i++)
    {
        /* XXX: replace this bytes retrieval with Capstone internal data since it already contains this info */
        NSRange range = NSMakeRange(fileOffset,0);
        NSString * lastReadHex;
        [dataController read_bytes:range length:cs_insn[i].size lastReadHex:&lastReadHex];
        /* format the disassembly output using Capstone strings */
        NSString *asm_string = [NSString stringWithFormat:@"%-10s\t%s", cs_insn[i].mnemonic, cs_insn[i].op_str];
        [node.details appendRow:[NSString stringWithFormat:@"%.8X", fileOffset]
                               :lastReadHex
                               :asm_string
                               :@""];
        /* advance to next instruction */
        fileOffset += cs_insn[i].size;
    }
    cs_free(cs_insn, disasm_count);
    cs_close(&cs_handle);
    // close last block
    if (symbolName)
    {
        [node.details setAttributesFromRowIndex:bookmark:MVMetaDataAttributeName,symbolName,nil];
        [node.details setAttributes:MVUnderlineAttributeName,@"YES",nil];
    }
    
    return node;
}

@end
