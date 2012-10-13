/*
 *  SectionContents.mm
 *  MachOView
 *
 *  Created by psaghelyi on 15/09/2010.
 *
 */

#import "Common.h"
#import "SectionContents.h"
#import "CRTFootPrints.h"
#import "ReadWrite.h"
#import "DataController.h"

#include "disasm.h"

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
    uint32_t ptr = [self read_uint32:range lastReadHex:&lastReadHex];
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
    uint64_t ptr = [self read_uint64:range lastReadHex:&lastReadHex];
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
    NSString * symbolName = [self read_string:range lastReadHex:&lastReadHex];
    
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
    NSData * data = [self read_bytes:range length:stride lastReadHex:&lastReadHex];

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
    [self read_uint32:range lastReadHex:&lastReadHex];
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
    [self read_uint64:range lastReadHex:&lastReadHex];
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
    [self read_bytes:range length:stride lastReadHex:&lastReadHex];
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
    [self read_bytes:range length:stride lastReadHex:&lastReadHex];
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
    data = [self read_bytes:range length:7 lastReadHex:&lastReadHex];
    address = *(uint32_t *)((uint8_t *)data.bytes + 2);
    [node.details appendRow:[NSString stringWithFormat:@"%.8lX", range.location]
                           :lastReadHex
                           :@"cmpl  $0x00,_fast_lazy_bind"
                           :[self findSymbolAtRVA:address]];

    [self read_bytes:range length:2 lastReadHex:&lastReadHex];
    [node.details appendRow:[NSString stringWithFormat:@"%.8lX", range.location]
                           :lastReadHex
                           :@"jne  $0x0D"
                           :@""];

    [self read_bytes:range length:4 lastReadHex:&lastReadHex];
    [node.details appendRow:[NSString stringWithFormat:@"%.8lX", range.location]
                           :lastReadHex
                           :@"movl  %eax,4(%esp)"
                           :@""];

    [self read_bytes:range length:1 lastReadHex:&lastReadHex];
    [node.details appendRow:[NSString stringWithFormat:@"%.8lX", range.location]
                           :lastReadHex
                           :@"popl  %eax"
                           :@""];

    [self read_bytes:range length:3 lastReadHex:&lastReadHex];
    [node.details appendRow:[NSString stringWithFormat:@"%.8lX", range.location]
                           :lastReadHex
                           :@"xchgl  (%esp),%eax"
                           :@""];

    data = [self read_bytes:range length:5 lastReadHex:&lastReadHex];
    address = [self fileOffsetToRVA:NSMaxRange(range) + *(uint32_t *)((uint8_t *)data.bytes + 1)];
    [node.details appendRow:[NSString stringWithFormat:@"%.8lX", range.location]
                           :lastReadHex
                           :@"jmpl  dyld_stub_binding_helper"
                           :[self findSymbolAtRVA:address]];

    [self read_bytes:range length:3 lastReadHex:&lastReadHex];
    [node.details appendRow:[NSString stringWithFormat:@"%.8lX", range.location]
                           :lastReadHex
                           :@"addl  $0x04,%esp"
                           :@""];

    data = [self read_bytes:range length:5 lastReadHex:&lastReadHex];
    address = *(uint32_t *)((uint8_t *)data.bytes + 1);
    [node.details appendRow:[NSString stringWithFormat:@"%.8lX", range.location]
                           :lastReadHex
                           :@"pushl  imageloadercache"
                           :[self findSymbolAtRVA:address]];

    data = [self read_bytes:range length:6 lastReadHex:&lastReadHex];
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
    data = [self read_bytes:range length:5 lastReadHex:&lastReadHex];
    address = *(uint32_t *)((uint8_t *)data.bytes + 1);
    [node.details appendRow:[NSString stringWithFormat:@"%.8lX", range.location]
                           :lastReadHex
                           :@"pushl  imageloadercache"
                           :[self findSymbolAtRVA:address]];
    
    data = [self read_bytes:range length:6 lastReadHex:&lastReadHex];
    address = *(uint32_t *)((uint8_t *)data.bytes + 2);
    [node.details appendRow:[NSString stringWithFormat:@"%.8lX", range.location]
                           :lastReadHex
                           :@"jmp  *_fast_lazy_bind"
                           :[self findSymbolAtRVA:address]];

    [self read_bytes:range length:1 lastReadHex:&lastReadHex];
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
{
  MVNodeSaver nodeSaver;
  MVNode * node = [parent insertChildWithDetails:caption location:location length:length saver:nodeSaver]; 
  
  // accumulate search info
  NSUInteger bookmark = node.details.rowCount;
  NSString * symbolName = nil;
  
  if (length == 0) // prevent of attempting to parse zero length sections
  {
    return node;
  }

  // prepare disassembler params
  //===========================================================================
  MATCH_STRUCT(mach_header,imageOffset);
  
  struct dysymtab_command const * dysymtab_command = NULL;
  for (CommandVector::const_iterator cmdIter = commands.begin(); cmdIter != commands.end(); ++cmdIter)
  {
    struct load_command const * load_command = (struct load_command const *)(*cmdIter);
    if (load_command->cmd == LC_DYSYMTAB)
    {
      dysymtab_command = (struct dysymtab_command const *)load_command; 
      break;
    }
  }
  
  char *                    ot_sect = (char*)[dataController.fileData bytes] + location;
  uint32_t                  ot_left = length;
  uint64_t                  ot_addr = ([self is64bit] == NO ? [self fileOffsetToRVA:location] : [self fileOffsetToRVA64:location]);
  uint64_t                  ot_sect_addr = ot_addr;
  enum byte_sex             ot_object_byte_sex = LITTLE_ENDIAN_BYTE_SEX; // the only one we support so far
  struct nlist *            ot_symbols = (symbols.empty() ? NULL : const_cast<struct nlist *>(symbols[0]));
  struct nlist_64 *         ot_symbols64 = (symbols_64.empty() ? NULL : const_cast<struct nlist_64 *>(symbols_64[0]));
  uint32_t                  ot_nsymbols = ([self is64bit] == NO ? symbols.size() : symbols_64.size());
  char *                    ot_strings = const_cast<char *>(strtab);
  uint32_t                  ot_strings_size = (char *)[dataController.fileData bytes] - strtab;
  uint32_t *                ot_indirect_symbols = (dysymtab_command ? (uint32_t*)((char*)[dataController.fileData bytes] + dysymtab_command->indirectsymoff + imageOffset) : NULL);
  uint32_t                  ot_nindirect_symbols = (dysymtab_command ? dysymtab_command->nindirectsyms : 0);
  struct load_command *     ot_load_commands = const_cast<struct load_command *>(commands[0]);
  uint32_t                  ot_ncmds = commands.size();
  uint32_t                  ot_sizeofcmds = mach_header->sizeofcmds;
  cpu_type_t                ot_cputype = mach_header->cputype;
  cpu_subtype_t             ot_cpu_subtype = mach_header->cpusubtype;
  bool                      ot_verbose = true;
  bool                      ot_llvm_mc = false;
  
  vector<symbol> sorted_symbols;
  set<uint64_t> thumbSymbols;
  
  if (mach_header->cputype == CPU_TYPE_ARM && 
      (mach_header->cpusubtype == CPU_SUBTYPE_ARM_V6 ||
       mach_header->cpusubtype == CPU_SUBTYPE_ARM_V7 ||
       mach_header->cpusubtype == CPU_SUBTYPE_ARM_V7F ||
       mach_header->cpusubtype == CPU_SUBTYPE_ARM_V7K ||
       mach_header->cpusubtype == CPU_SUBTYPE_ARM_V7S))
  for(uint32_t i = 0; i < ot_nsymbols; ++i)
  {
    uint8_t n_type;
    uint16_t n_desc;
    uint64_t n_value;
    
    if([self is64bit] == NO)
    {
      struct nlist const * nlist = symbols.at(i);
      n_type = nlist->n_type;
      n_desc = nlist->n_desc;
      n_value = nlist->n_value;
    }
    else
    {
      struct nlist_64 const * nlist_64 = symbols_64.at(i);
      n_type = nlist_64->n_type;
      n_desc = nlist_64->n_desc;
      n_value = nlist_64->n_value;
    }
    
    if((n_type & N_TYPE) == N_SECT && (n_desc & N_ARM_THUMB_DEF))
    {
      thumbSymbols.insert(n_value);
    }
  }
  
  in_thumb = (mach_header->cputype != CPU_TYPE_ARM && mach_header->cpusubtype == CPU_SUBTYPE_ARM_V7);
  
  NSEnumerator * enumerator = [symbolNames keyEnumerator];
  id key;
  while ((key = [enumerator nextObject]) != nil) 
  {
    NSNumber * symbolIndex = (NSNumber *)key;
    
    // skip external symbols
    if (([self is64bit] == NO && (int32_t)[symbolIndex unsignedLongValue] < 0) ||
        (int64_t)[symbolIndex unsignedLongLongValue] < 0)
    {
      continue;
    }

    struct symbol symbol;
    symbol.name = strdup(CSTRING([symbolNames objectForKey:key]));
    symbol.n_value = [symbolIndex unsignedLongLongValue];
    symbol.is_thumb = (thumbSymbols.find(symbol.n_value) != thumbSymbols.end());
    
    sorted_symbols.push_back(symbol);
  }
  
  qsort(&sorted_symbols[0], sorted_symbols.size(), sizeof(struct symbol),
        (int (*)(const void *, const void *))sym_compare);

  struct symbol *           ot_sorted_symbols = &sorted_symbols[0];
  uint32_t                  ot_nsorted_symbols = sorted_symbols.size();
  
  struct relocation_info *  ot_sorted_relocs = (struct relocation_info *)((char *)[dataController.fileData bytes] + reloff);
  uint32_t                  ot_nsorted_relocs = nreloc;

  //===========================================================================

  do {

    // catch thread cancellation request
    if ([backgroundThread isCancelled])
    {
      break;
    }
    
    // pipes makes us to run disassembling exclusively on a single thread
    [pipeCondition lock];
    while (numIOThread > 0)
    {
      [pipeCondition wait];
    }
    
    int pfdout[3]; // 0:read 1:write 2:stdout
    if (pipe (pfdout) != 0) 
    {
      [NSException raise:@"pipe" format:@"unable to create pipes"];
    }
    
    // save standard output descriptor
    pfdout[2] = dup(STDOUT_FILENO);
    
    // redirect
    close(STDOUT_FILENO);
    dup2 (pfdout[1], STDOUT_FILENO);
  
    // run disassembler line by line
    setlinebuf(stdout);
    
    NSUInteger nAsmLine = 0;
    do
    {
      uint32_t parsed_bytes = 
        (mach_header->cputype != CPU_TYPE_ARM
         ? i386_disassemble(
                            ot_sect,
                            ot_left,
                            ot_addr,
                            ot_sect_addr,
                            ot_object_byte_sex,
                            ot_sorted_relocs,
                            ot_nsorted_relocs,
                            ot_symbols,
                            ot_symbols64,
                            ot_nsymbols,
                            ot_sorted_symbols,
                            ot_nsorted_symbols,
                            ot_strings,
                            ot_strings_size,
                            ot_indirect_symbols,
                            ot_nindirect_symbols,
                            ot_cputype,
                            ot_load_commands,
                            ot_ncmds,
                            ot_sizeofcmds,
                            ot_verbose,
                            ot_llvm_mc
                            )
         : arm_disassemble(
                           ot_sect,
                           ot_left,
                           ot_addr,
                           ot_sect_addr,
                           ot_object_byte_sex,
                           ot_sorted_relocs,
                           ot_nsorted_relocs,
                           ot_symbols,
                           ot_nsymbols,
                           ot_sorted_symbols,
                           ot_nsorted_symbols,
                           ot_strings,
                           ot_strings_size,
                           ot_indirect_symbols,
                           ot_nindirect_symbols,
                           ot_load_commands,
                           ot_ncmds,
                           ot_sizeofcmds,
                           ot_cpu_subtype,
                           ot_verbose
                           )
       );
        
      // read from pipe
      char buf[0x1000], *pbuf = buf;
      ssize_t lenbuf = read(pfdout[0], buf, sizeof(buf));
      buf[lenbuf] = '\0'; // terminate buffer
      size_t field_start_pos = 0; // start position in buffer of the current field
      
      while (pbuf - buf < lenbuf)
      {
        if (*pbuf == '\n') // newline or
        {
          *pbuf = '\0'; // clear newline
          
          char const * symbol_name = guess_symbol(ot_addr,
                                                  ot_sorted_symbols,
                                                  ot_nsorted_symbols);
          // print label if any
          if (symbol_name)
          {
            // close previous block (if any)
            if (symbolName)
            {
              [node.details setAttributesFromRowIndex:bookmark:MVMetaDataAttributeName,symbolName,nil];
              [node.details setAttributes:MVUnderlineAttributeName,@"YES",nil];
            }

            // start new block
            bookmark = node.details.rowCount;
            [node.details appendRow:@""
                                   :@""
                                   :[NSString stringWithFormat:@"%@:", (symbolName = NSSTRING(symbol_name))]
                                   :@""];
                
            [node.details setAttributes:MVCellColorAttributeName,[NSColor orangeColor],nil];
          }
              
          // print one line of asm
          uint32_t fileOffset = ([self is64bit] == NO ? [self RVAToFileOffset:(uint32_t)ot_addr] : [self RVA64ToFileOffset:ot_addr]);
          NSRange range = NSMakeRange(fileOffset,0);
          NSString * lastReadHex;
          [self read_bytes:range length:parsed_bytes lastReadHex:&lastReadHex];
          [node.details appendRow:[NSString stringWithFormat:@"%.8X", fileOffset]
                                 :lastReadHex
                                 :NSSTRING(buf)
                                 :@""];
              
          break; // stop processing after the first new line
        }
        else if (*pbuf == '\t')
        {
          // replace tabs with spaces in order to keep indention
          size_t wsn = TAB_WIDTH - ((pbuf - buf - field_start_pos) % TAB_WIDTH);
          *pbuf = ' '; // change the tab char to space
              
          // shift everything after the tab char right
          for (char * p = buf + lenbuf; p > pbuf; --p)
          {
            *(p + wsn - 1) = *p;
            *p = ' ';
          }
              
          // adjust pointers
          pbuf += wsn;
          lenbuf += wsn;
              
          // store start position of the field for the next tab
          field_start_pos = pbuf - buf;
        }
        else
        {
          ++pbuf;
        }
      }
      
      // synchronize disassembler
      ot_left -= parsed_bytes;
      ot_sect += parsed_bytes;
      ot_addr += parsed_bytes;
      
      // inner loop forces to switch task after every 4096 lines of assembly
    } while (ot_addr < ot_sect_addr + length && (++nAsmLine % 0x1000));

    // close read handle
    close (pfdout[0]);
    
    // close write handle
    close (pfdout[1]);
    
    // restore standard outputs
    dup2 (pfdout[2], STDOUT_FILENO);
    close (pfdout[2]);
    
    [pipeCondition unlock];

  } while (ot_addr < ot_sect_addr + length);
  
  // clean up symbols
  for (vector<symbol>::iterator iter = sorted_symbols.begin();
       iter != sorted_symbols.end();
       ++iter)
  {
    free(iter->name);
  }
  
  // close last block
  if (symbolName)
  {
    [node.details setAttributesFromRowIndex:bookmark:MVMetaDataAttributeName,symbolName,nil];
    [node.details setAttributes:MVUnderlineAttributeName,@"YES",nil];
  }
  
  return node;
}

@end
