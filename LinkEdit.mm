/*
 *  LinkEdit.mm
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
#import "LinkEdit.h"
#import "ReadWrite.h"
#import "DataController.h"

using namespace std;

//============================================================================
@implementation MachOLayout (LinkEdit)

//-----------------------------------------------------------------------------
- (MVNode *) createRelocNode:(MVNode *)parent
                     caption:(NSString *)caption
                    location:(uint32_t)location
                      length:(uint32_t)length
                 baseAddress:(uint32_t)baseAddress // start of the section containing the relocation (image: start of the first segment)
{
  MVNodeSaver nodeSaver;
  MVNode * node = [parent insertChildWithDetails:caption location:location length:length saver:nodeSaver]; 
  
  NSRange range = NSMakeRange(location,0);
  NSString * lastReadHex;
  
  MATCH_STRUCT(mach_header,imageOffset);
  
  struct scattered_relocation_info const * prev_scattered_relocation_info = NULL; // for sectdiff & pair
  
  for (uint32_t nreloc = 0; nreloc < length / sizeof(struct relocation_info); ++nreloc)
  {
    if ([backgroundThread isCancelled]) break;
    
    // normal:    relocation_info != NULL, scattered_relocation_info == NULL
    // scattered: relocation_info == NULL, scattered_relocation_info != NULL
    
    MATCH_STRUCT(relocation_info,location + nreloc * sizeof(struct relocation_info))
    
    struct scattered_relocation_info const * scattered_relocation_info = NULL;
    
    if (relocation_info->r_address & R_SCATTERED)
    {
      scattered_relocation_info = (struct scattered_relocation_info const *)relocation_info;
      relocation_info = NULL;
    }
    
    // accumulate search info
    NSUInteger bookmark = node.details.rowCount;
    NSString * symbolName = nil;
    NSColor * color = nil;
    
    // read the first half of the entry
    [dataController read_uint32:range lastReadHex:&lastReadHex];
    [node.details appendRow:[NSString stringWithFormat:@"%.8lX", range.location]
                           :lastReadHex
                           :@"Address"
                           :[NSString stringWithFormat:@"0x%X", relocation_info 
                             ? relocation_info->r_address + baseAddress 
                             : scattered_relocation_info->r_address + baseAddress]];
    
    [node.details appendRow:@"":@"":@"Scattered":scattered_relocation_info ? @"True" : @"False"];
    
    // read the second half of the entry
    [dataController read_uint32:range lastReadHex:&lastReadHex];
    
    if (relocation_info)
    {
      uint32_t relocLocation = [self RVAToFileOffset:baseAddress + relocation_info->r_address];
      NSRange rangeReloc = NSMakeRange(relocLocation,0);
      uint32_t relocValue = [dataController read_uint32:rangeReloc];
      uint32_t relocLength = (1 << relocation_info->r_length);
      NSParameterAssert(relocLength == sizeof(uint32_t));
      
      // adjust for PC relative relocs
      if (relocation_info->r_pcrel)
      {
        relocValue += relocation_info->r_address + baseAddress + relocLength;
      }

      if (relocation_info->r_extern)
      {
        // target is a symbol
        if (relocation_info->r_symbolnum >= symbols.size())
        {
          [NSException raise:@"Symbol"
                      format:@"index is out of range %u", relocation_info->r_symbolnum];
        }
        
        struct nlist const * nlist = [self getSymbolByIndex:relocation_info->r_symbolnum];
        symbolName = NSSTRING(strtab + nlist->n_un.n_strx);
        
        [node.details appendRow:[NSString stringWithFormat:@"%.8lX", range.location]
                               :lastReadHex
                               :@"Symbol"
                               :(nlist->n_type & N_TYPE) == N_SECT 
                                  ? [NSString stringWithFormat:@"0x%X (%@)", nlist->n_value, symbolName]
                                  : symbolName];
        
        [symbolNames setObject:[NSString stringWithFormat:@"%@->%@",
                                [self findSymbolAtRVA:[self fileOffsetToRVA:relocLocation]],symbolName]
                        forKey:[NSNumber numberWithUnsignedLong:[self fileOffsetToRVA:relocLocation]]];

        if ((nlist->n_type & N_TYPE) == N_SECT)
        {
          // reference to local symbol
          relocValue += nlist->n_value;
        }
        else 
        {
          // reference to undefined external symbol

          uint32_t relocAddend = relocValue;
          
          // use the negative index of the symbol (hope that will not overlap)
          relocValue += *symbols.begin() - nlist - 1;
          
          if (relocAddend != 0) 
          {
            [node.details appendRow:@"":@"":@"Addend":(int32_t)relocAddend < 0 
                                                        ? [NSString stringWithFormat:@"-0x%X",-relocAddend] 
                                                        : [NSString stringWithFormat:@"0x%X",relocAddend]];
          }
        }
      }
      else // r_symbolnum means section index
      {
        if (relocation_info->r_symbolnum == R_ABS)
        {
          // absolute address
          [node.details appendRow:[NSString stringWithFormat:@"%.8lX", range.location]
                                 :lastReadHex
                                 :@"Section"
                                 :@"R_ABS"];
        }
        else
        {
          // section relative (symbolNum means sectionNum)
          if (relocation_info->r_symbolnum >= sections.size())
          {
            [NSException raise:@"Section"
                        format:@"index is out of range %u", relocation_info->r_symbolnum];
          }
          
          struct section const * section = [self getSectionByIndex:relocation_info->r_symbolnum];
          
          NSString * sectionName = [NSString stringWithFormat:@"(%s,%s)", 
                                    string(section->segname,16).c_str(),
                                    string(section->sectname,16).c_str()];
          
          [node.details appendRow:[NSString stringWithFormat:@"%.8lX", range.location]
                                 :lastReadHex
                                 :@"Section"
                                 :[NSString stringWithFormat:@"%u %@", relocation_info->r_symbolnum, sectionName]];
          
          [node.details appendRow:@"":@"":@"Target":(symbolName = [self findSymbolAtRVA:relocValue])];
          
          [symbolNames setObject:[NSString stringWithFormat:@"%@->%@",
                                  [self findSymbolAtRVA:[self fileOffsetToRVA:relocLocation]],symbolName]
                          forKey:[NSNumber numberWithUnsignedLong:[self fileOffsetToRVA:relocLocation]]];
        }
      }

      // update real data
      [self addRelocAtFileOffset:relocLocation withLength:relocLength andValue:relocValue];
      //NSLog(@"%@ %.8X --> %@",[self findSectionContainsRVA:[self fileOffsetToRVA:relocLocation]],[self fileOffsetToRVA:relocLocation],[self findSymbolAtRVA:relocValue]);
    } 
    else 
      
    //=============================== scattered relocation ===============================
      
    if (scattered_relocation_info)
    {
      NSParameterAssert(scattered_relocation_info->r_pcrel == false); // have not faced with this yet
      
      uint32_t r_type = scattered_relocation_info->r_type;
      if (
          (mach_header->cputype == CPU_TYPE_I386 && (r_type == GENERIC_RELOC_SECTDIFF || r_type == GENERIC_RELOC_LOCAL_SECTDIFF))
          ||
          (mach_header->cputype == CPU_TYPE_ARM && (r_type == ARM_RELOC_SECTDIFF || r_type == ARM_RELOC_LOCAL_SECTDIFF))
          )
      {
        prev_scattered_relocation_info = scattered_relocation_info;
      }
      else if (
               ((mach_header->cputype == CPU_TYPE_I386 && r_type == GENERIC_RELOC_PAIR)
               ||
               (mach_header->cputype == CPU_TYPE_ARM && r_type == ARM_RELOC_PAIR))
               && prev_scattered_relocation_info
               )
      {
        //read original content at relocation
        uint32_t relocLocation = [self RVAToFileOffset:baseAddress + prev_scattered_relocation_info->r_address];
        uint32_t relocLength = (1 << prev_scattered_relocation_info->r_length);
        NSAssert1(relocLength == sizeof(uint32_t), @"unsupported reloc length (%u)", relocLength);
        NSRange rangeReloc = NSMakeRange(relocLocation,0);
        uint32_t relocValue = [dataController read_uint32:rangeReloc];
        uint32_t relocAddend = relocValue - (prev_scattered_relocation_info->r_value - scattered_relocation_info->r_value);

        // the relocation value only differs if it has an addend
        if (relocAddend != 0)
        {
          [node.details appendRow:@"":@"":@"Addend"
                                 :(int32_t)relocAddend < 0 
                                  ? [NSString stringWithFormat:@"-0x%X", -relocAddend] 
                                  : [NSString stringWithFormat:@"0x%X", relocAddend]];
          
          // update real data
          relocValue += relocAddend;
          [self addRelocAtFileOffset:relocLocation withLength:relocLength andValue:relocValue];
          //NSLog(@"%@ %.8X --> %@",[self findSectionContainsRVA:[self fileOffsetToRVA:relocLocation]],[self fileOffsetToRVA:relocLocation],[self findSymbolAtRVA:relocValue]);
        }

        prev_scattered_relocation_info = NULL; // reset
      }
    }
    
    //=============================== normal relocations ===============================
    
    if (mach_header->cputype == CPU_TYPE_I386)
    {
      uint32_t r_type = (relocation_info ? relocation_info->r_type : scattered_relocation_info->r_type);
      
      [node.details appendRow:@"":@"":@"Type"
                             :r_type == GENERIC_RELOC_VANILLA ? @"GENERIC_RELOC_VANILLA" :
                              r_type == GENERIC_RELOC_PAIR ? @"GENERIC_RELOC_PAIR" :
                              r_type == GENERIC_RELOC_SECTDIFF ? @"GENERIC_RELOC_SECTDIFF" :
                              r_type == GENERIC_RELOC_PB_LA_PTR ? @"GENERIC_RELOC_PB_LA_PTR" :
                              r_type == GENERIC_RELOC_LOCAL_SECTDIFF ? @"GENERIC_RELOC_LOCAL_SECTDIFF" : 
                              r_type == GENERIC_RELOC_TLV ? @"GENERIC_RELOC_TLV" : @"?????"];
    }
    else if (mach_header->cputype == CPU_TYPE_ARM)
    {
      uint32_t r_type = (relocation_info ? relocation_info->r_type : scattered_relocation_info->r_type);
      
      [node.details appendRow:@"":@"":@"Type"
                             :r_type == ARM_RELOC_VANILLA ? @"ARM_RELOC_VANILLA" :
                              r_type == ARM_RELOC_PAIR ? @"ARM_RELOC_PAIR" :
                              r_type == ARM_RELOC_SECTDIFF ? @"ARM_RELOC_SECTDIFF" :
                              r_type == ARM_RELOC_LOCAL_SECTDIFF ? @"ARM_RELOC_LOCAL_SECTDIFF" :
                              r_type == ARM_RELOC_PB_LA_PTR ? @"ARM_RELOC_PB_LA_PTR" : 
                              r_type == ARM_RELOC_BR24 ? @"ARM_RELOC_BR24" :
                              r_type == ARM_THUMB_RELOC_BR22 ? @"ARM_THUMB_RELOC_BR22" : 
                              r_type == ARM_THUMB_32BIT_BRANCH ? @"ARM_THUMB_32BIT_BRANCH" :
                              r_type == ARM_RELOC_HALF ? @"ARM_RELOC_HALF" : 
                              r_type == ARM_RELOC_HALF_SECTDIFF ? @"ARM_RELOC_HALF_SECTDIFF" : @"?????"];
    }
    
    if (relocation_info)
    {
      [node.details appendRow:@"":@"":@"External"
                             :relocation_info->r_extern ? @"True" : @"False"];
    }
    
    [node.details appendRow:@"":@"":@"PCRelative"
                           :(relocation_info && relocation_info->r_pcrel) || (scattered_relocation_info && scattered_relocation_info->r_pcrel) 
                            ? @"True" : @"False"];
    
    [node.details appendRow:@"":@"":@"Length"
                           :[NSString stringWithFormat:@"%u",
                             relocation_info ? (1 << relocation_info->r_length) : (1 << scattered_relocation_info->r_length)]];
    
    if (scattered_relocation_info)
    {
      [node.details appendRow:[NSString stringWithFormat:@"%.8lX", range.location]
                             :lastReadHex
                             :@"Value"
                             :(symbolName = [self findSymbolAtRVA:scattered_relocation_info->r_value])];
      
      color = [NSColor magentaColor];
    }
    
    [node.details setAttributesFromRowIndex:bookmark:MVMetaDataAttributeName,symbolName,
                                                      MVCellColorAttributeName,color,nil];
    [node.details setAttributes:MVUnderlineAttributeName,@"YES",nil];
  } // loop
  
  return node;
}

//-----------------------------------------------------------------------------
- (MVNode *) createReloc64Node:(MVNode *)parent
                       caption:(NSString *)caption
                      location:(uint32_t)location
                        length:(uint32_t)length
                   baseAddress:(uint64_t)baseAddress // start of the section containing the relocation (image: start of the first segment)
{
  MVNodeSaver nodeSaver;
  MVNode * node = [parent insertChildWithDetails:caption location:location length:length saver:nodeSaver]; 
  
  NSRange range = NSMakeRange(location,0);
  NSString * lastReadHex;
  
  MATCH_STRUCT(mach_header_64,imageOffset);
  
  struct relocation_info const * prev_relocation_info = NULL;
  
  for (uint32_t nreloc = 0; nreloc < length / sizeof(struct relocation_info); ++nreloc)
  {
    if ([backgroundThread isCancelled]) break;
    
    // In the Mac OS X x86-64 environment scattered relocations are not used. Compiler-generated code
    // uses mostly external relocations, in which the r_extern bit is set to 1 and the r_symbolnum field contains
    // the symbol-table index of the target label.
    
    MATCH_STRUCT(relocation_info,location + nreloc * sizeof(struct relocation_info))
    
    uint32_t relocLength = (1 << relocation_info->r_length);
    NSAssert1(relocLength == sizeof(uint32_t) || relocLength == sizeof(uint64_t), @"unsupported reloc length (%u)", relocLength);
    
    // accumulate search info
    NSUInteger bookmark = node.details.rowCount;
    NSString * symbolName = nil;
    NSColor * color = nil;

    // read the first half of the entry
    [dataController read_uint32:range lastReadHex:&lastReadHex];
    [node.details appendRow:[NSString stringWithFormat:@"%.8lX", range.location]
                           :lastReadHex
                           :@"Address"
                           :[NSString stringWithFormat:@"0x%qX", relocation_info->r_address + baseAddress]];

    // read the second half of the entry
    [dataController read_uint32:range lastReadHex:&lastReadHex];
    
    //========================================================================
    if (relocation_info->r_extern)
    {
      uint32_t relocLocation = [self RVA64ToFileOffset:baseAddress + relocation_info->r_address];
      NSRange rangeReloc = NSMakeRange(relocLocation,0);

      // target symbol
      if (relocation_info->r_symbolnum >= symbols_64.size())
      {
        [NSException raise:@"Symbol"
                    format:@"symbol is out of range %u", relocation_info->r_symbolnum];
      }
      
      struct nlist_64 const * nlist_64 = [self getSymbol64ByIndex:relocation_info->r_symbolnum];
      symbolName = NSSTRING(strtab + nlist_64->n_un.n_strx);
      
      [node.details appendRow:[NSString stringWithFormat:@"%.8lX", range.location]
                             :lastReadHex
                             :@"Symbol"
                             :(nlist_64->n_type & N_TYPE) == N_SECT 
                                ? [NSString stringWithFormat:@"0x%qX (%@)", nlist_64->n_value, symbolName]
                                : symbolName];
      
      [symbolNames setObject:[NSString stringWithFormat:@"%@->%@",
                              [self findSymbolAtRVA64:[self fileOffsetToRVA64:relocLocation]],symbolName]
                      forKey:[NSNumber numberWithUnsignedLongLong:[self fileOffsetToRVA64:relocLocation]]];

      // For the x86_64 architecure on Mac OS X it is possible to
      // encode a signed 32-bit expression of the form:
      // "add_symbol - subtract_symbol + number" 
      // using two relocation entries pointing at the same 32-bits.
      // The first one has to be a X86_64_RELOC_SUBTRACTOR then must
      // be followed by a X86_64_RELOC_UNSIGNED.
      
      if ((mach_header_64->cputype == CPU_TYPE_X86_64 && relocation_info->r_type == X86_64_RELOC_SUBTRACTOR)
          ||
          (mach_header_64->cputype == CPU_TYPE_ARM64 && relocation_info->r_type == ARM64_RELOC_SUBTRACTOR))
      {
        color = [NSColor magentaColor];
        prev_relocation_info = relocation_info;
      } 
      else if (prev_relocation_info)
      {
        // reference computed from difference of two symbols
        //============================================

        NSAssert(!(mach_header_64->cputype == CPU_TYPE_X86_64) || relocation_info->r_type == X86_64_RELOC_UNSIGNED, @"X86_64_RELOC_SUBTRACTOR must be followed by X86_64_RELOC_UNSIGNED");
        NSAssert(!(mach_header_64->cputype == CPU_TYPE_ARM64) || relocation_info->r_type == ARM64_RELOC_UNSIGNED, @"ARM64_RELOC_SUBTRACTOR must be followed by ARM64_RELOC_UNSIGNED");
        NSParameterAssert (relocation_info->r_address == prev_relocation_info->r_address);
        
        color = [NSColor magentaColor];
        
        if (relocation_info->r_symbolnum >= symbols_64.size())
        {
          [NSException raise:@"Symbol"
                      format:@"index is out of range %u", relocation_info->r_symbolnum];
        }
        
        struct nlist_64 const * prev_nlist_64 = [self getSymbol64ByIndex:prev_relocation_info->r_symbolnum];
        
        if (relocLength == sizeof(uint32_t))
        {
          uint32_t relocAddend = [dataController read_uint32:rangeReloc];
          if (relocAddend != 0) 
          {
            [node.details appendRow:@"":@"":@"Addend"
                                   :(int32_t)relocAddend < 0 
                                    ? [NSString stringWithFormat:@"-0x%X",-relocAddend] 
                                    : [NSString stringWithFormat:@"0x%X",relocAddend]];
          }
          uint32_t relocValue = nlist_64->n_value - prev_nlist_64->n_value + relocAddend;
          
          // update real data
          [self addRelocAtFileOffset:relocLocation withLength:relocLength andValue:relocValue];
          //NSLog(@"diff32:  %@ %.16qX --> (%u) %@",[self findSectionContainsRVA64:[self fileOffsetToRVA64:relocLocation]],[self fileOffsetToRVA64:relocLocation],relocLength,[self findSymbolAtRVA64:relocValue]);
        }
        else if (relocLength == sizeof(uint64_t))
        {
          uint64_t relocAddend = [dataController read_uint64:rangeReloc];
          if (relocAddend != 0) 
          {
            [node.details appendRow:@"":@"":@"Addend"
                                   :(int64_t)relocAddend < 0
                                    ? [NSString stringWithFormat:@"-0x%qX",-relocAddend] 
                                    : [NSString stringWithFormat:@"0x%qX",relocAddend]];
          }
          uint64_t relocValue = nlist_64->n_value - prev_nlist_64->n_value + relocAddend;
          
          // update real data
          [self addRelocAtFileOffset:relocLocation withLength:relocLength andValue:relocValue];
          //NSLog(@"diff64:  %@ %.16qX --> (%u) %@",[self findSectionContainsRVA64:[self fileOffsetToRVA64:relocLocation]],[self fileOffsetToRVA64:relocLocation],relocLength,[self findSymbolAtRVA64:relocValue]);
        }
        prev_relocation_info = NULL; // reset
      } 
      else if ((nlist_64->n_type & N_TYPE) == N_SECT)
      {
        // reference to local symbol
        //============================================
        
        if (relocLength == sizeof(uint32_t))
        {
          // 32bit signed PC Rel
          NSParameterAssert(relocation_info->r_pcrel == true);
          uint32_t relocValue = nlist_64->n_value - relocation_info->r_address - baseAddress - relocLength;
          uint32_t relocAddend = [dataController read_uint32:rangeReloc];

          if (mach_header_64->cputype == CPU_TYPE_X86_64)
          {
            relocAddend -= (relocation_info->r_type == X86_64_RELOC_SIGNED_1 ? 1 :
                                   relocation_info->r_type == X86_64_RELOC_SIGNED_2 ? 2 :
                                   relocation_info->r_type == X86_64_RELOC_SIGNED_4 ? 4 : 0);
          }
          
          if (relocAddend != 0)
          {
            [node.details appendRow:@"":@"":@"Addend"
                                   :(int32_t)relocAddend < 0 
                                    ? [NSString stringWithFormat:@"-0x%X",-relocAddend] 
                                    : [NSString stringWithFormat:@"0x%X",relocAddend]];
          }
          
          // update real data
          relocValue += relocAddend;
          [self addRelocAtFileOffset:relocLocation withLength:relocLength andValue:relocValue];
          //NSLog(@"local32: %@ %.16qX --> (%u) %@",[self findSectionContainsRVA64:[self fileOffsetToRVA64:relocLocation]],[self fileOffsetToRVA64:relocLocation],relocLength,[self findSymbolAtRVA64:relocValue]);
        }
        else if (relocLength == sizeof(uint64_t))
        {
          // 64bit unsigned direct
          NSParameterAssert(relocation_info->r_pcrel == false);
          uint64_t relocValue = nlist_64->n_value;
          uint64_t relocAddend = [dataController read_uint64:rangeReloc];
          if (relocAddend != 0) 
          {
            [node.details appendRow:@"":@"":@"Addend"
                                   :(int64_t)relocAddend < 0
                                    ? [NSString stringWithFormat:@"-0x%qX",-relocAddend] 
                                    : [NSString stringWithFormat:@"0x%qX",relocAddend]];
          }
          
          // update real data
          relocValue += relocAddend;
          [self addRelocAtFileOffset:relocLocation withLength:relocLength andValue:relocValue];
          //NSLog(@"local64: %@ %.16qX --> (%u) %@",[self findSectionContainsRVA64:[self fileOffsetToRVA64:relocLocation]],[self fileOffsetToRVA64:relocLocation],relocLength,[self findSymbolAtRVA64:relocValue]);
        }
      }
      else
      {
        // reference to undefined external symbol
        //============================================
        
        NSParameterAssert((nlist_64->n_type & N_TYPE) == N_UNDF);  // N_PBUD is only in image
        
        if (relocLength == sizeof(uint32_t))
        {
          NSParameterAssert(relocation_info->r_pcrel == true);
          NSRange rangeReloc = NSMakeRange(relocLocation,0);
          uint32_t relocAddend = [dataController read_uint32:rangeReloc];
          
          if (mach_header_64->cputype == CPU_TYPE_X86_64)
          {
            relocAddend -= (relocation_info->r_type == X86_64_RELOC_SIGNED_1 ? 1 :
                                   relocation_info->r_type == X86_64_RELOC_SIGNED_2 ? 2 :
                                   relocation_info->r_type == X86_64_RELOC_SIGNED_4 ? 4 : 0);
          }
          
          if (relocAddend != 0) 
          {
            [node.details appendRow:@"":@"":@"Addend"
                                   :(int32_t)relocAddend < 0
                                    ? [NSString stringWithFormat:@"-0x%X",-relocAddend] 
                                    : [NSString stringWithFormat:@"0x%X",relocAddend]];
          }
          uint32_t relocValue = *symbols_64.begin() - nlist_64 - 1;
          relocValue -= relocation_info->r_address + baseAddress + relocLength; // it is PC relative
          
          // update real data
          relocValue += relocAddend;
          [self addRelocAtFileOffset:relocLocation withLength:relocLength andValue:relocValue];
          //NSLog(@"undef32: %@ %.16qX --> (%u) %@",[self findSectionContainsRVA64:[self fileOffsetToRVA64:relocLocation]],[self fileOffsetToRVA64:relocLocation],relocLength,[self findSymbolAtRVA64:relocValue]);
        }
        else 
        {
          NSParameterAssert(relocation_info->r_pcrel == false);
          NSRange rangeReloc = NSMakeRange(relocLocation,0);
          uint64_t relocAddend = [dataController read_uint64:rangeReloc];
          if (relocAddend != 0) 
          {
            [node.details appendRow:@"":@"":@"Addend"
                                   :(int64_t)relocAddend < 0 
                                    ? [NSString stringWithFormat:@"-0x%qX",-relocAddend]
                                    : [NSString stringWithFormat:@"0x%qX",relocAddend]];
          }
          uint64_t relocValue = *symbols_64.begin() - nlist_64 - 1;
          
          // update real data
          relocValue += relocAddend;
          [self addRelocAtFileOffset:relocLocation withLength:relocLength andValue:relocValue];
          //NSLog(@"undef64: %@ %.16qX --> (%u) %@",[self findSectionContainsRVA64:[self fileOffsetToRVA64:relocLocation]],[self fileOffsetToRVA64:relocLocation],relocLength,[self findSymbolAtRVA64:relocValue]);
        }
      }
    }
    else // r_symbolnum means section index
    {
      // section relative (symbolNum means sectionNum)
      if (relocation_info->r_symbolnum >= sections_64.size())
      {
        [NSException raise:@"Section"
                    format:@"index is out of range %u", relocation_info->r_symbolnum];
      }
      
      struct section_64 const * section_64 = [self getSection64ByIndex:relocation_info->r_symbolnum];
      
      NSString * sectionName = [NSString stringWithFormat:@"(%s,%s)", 
                                string(section_64->segname,16).c_str(),
                                string(section_64->sectname,16).c_str()];
      
      if (relocation_info->r_symbolnum == R_ABS)
      {
        // absolute address
        [node.details appendRow:[NSString stringWithFormat:@"%.8lX", range.location]
                               :lastReadHex
                               :@"Section"
                               :@"R_ABS"];
      }
      else
      {
        [node.details appendRow:[NSString stringWithFormat:@"%.8lX", range.location]
                               :lastReadHex
                               :@"Section"
                               :[NSString stringWithFormat:@"%u %@", relocation_info->r_symbolnum, sectionName]];
        
        uint32_t relocLocation = [self RVA64ToFileOffset:baseAddress + relocation_info->r_address];
        NSRange rangeReloc = NSMakeRange(relocLocation,0);
        uint64_t relocValue = 0;
        
        if ((mach_header_64->cputype == CPU_TYPE_X86_64 && relocation_info->r_type == X86_64_RELOC_SUBTRACTOR)
            ||
            (mach_header_64->cputype == CPU_TYPE_ARM64 && relocation_info->r_type == ARM64_RELOC_SUBTRACTOR))
        {
          prev_relocation_info = relocation_info;
        }
        else if (prev_relocation_info)
        {
          // TODO: calculate if we will ever be interested of the target 
          // (usually used only in debug_line section)
          prev_relocation_info = NULL;
        }
        else if (relocLength == sizeof(uint32_t))
        {
          relocValue = [dataController read_uint32:rangeReloc];

          if ((mach_header_64->cputype == CPU_TYPE_X86_64 && relocation_info->r_type == X86_64_RELOC_UNSIGNED)
              ||
              (mach_header_64->cputype == CPU_TYPE_ARM64 && relocation_info->r_type == ARM64_RELOC_UNSIGNED))
          {
            // 32bit direct relocation
            NSParameterAssert (relocation_info->r_pcrel == false);
          }
          else
          {
            // 32bit PC relative signed relocation
            NSParameterAssert (relocation_info->r_pcrel == true);
            relocValue += relocation_info->r_address + baseAddress + relocLength;
            
            if (mach_header_64->cputype == CPU_TYPE_X86_64)
            {
              relocValue -= (relocation_info->r_type == X86_64_RELOC_SIGNED_1 ? 1 :
                           relocation_info->r_type == X86_64_RELOC_SIGNED_2 ? 2 :
                           relocation_info->r_type == X86_64_RELOC_SIGNED_4 ? 4 : 0);
          }
            
          }
        }
        else if (relocLength == sizeof(uint64_t))
        {
          // 64bit direct relocation
          NSParameterAssert (!(mach_header_64->cputype == CPU_TYPE_X86_64) || relocation_info->r_type == X86_64_RELOC_UNSIGNED);
          NSParameterAssert (!(mach_header_64->cputype == CPU_TYPE_ARM64) || relocation_info->r_type == ARM64_RELOC_UNSIGNED);
          NSParameterAssert (relocation_info->r_pcrel == false);
          relocValue = [dataController read_uint64:rangeReloc];
        }
        else
        {
          NSAssert(NO, @"Unsupported 64bit reloc");
        }
        
        [node.details appendRow:@"":@"":@"Target":(symbolName = [self findSymbolAtRVA64:relocValue])];
        
        // update real data
        [self addRelocAtFileOffset:relocLocation withLength:relocLength andValue:relocValue];
        
        [symbolNames setObject:[NSString stringWithFormat:@"%@->%@",
                                [self findSymbolAtRVA64:[self fileOffsetToRVA64:relocLocation]],symbolName]
                        forKey:[NSNumber numberWithUnsignedLongLong:[self fileOffsetToRVA64:relocLocation]]];

        //NSLog(@"%@ %.16qX --> (%u) %@",[self findSectionContainsRVA64:[self fileOffsetToRVA64:relocLocation]],[self fileOffsetToRVA64:relocLocation],relocLength,[self findSymbolAtRVA64:relocValue]);
      }
    }
    //========== end of differentation 
    
    if (mach_header_64->cputype == CPU_TYPE_X86_64)
    {
    [node.details appendRow:@"":@"":@"Type"
                           :relocation_info->r_type == X86_64_RELOC_UNSIGNED ? @"X86_64_RELOC_UNSIGNED" :
                            relocation_info->r_type == X86_64_RELOC_SIGNED ? @"X86_64_RELOC_SIGNED" :
                            relocation_info->r_type == X86_64_RELOC_BRANCH ? @"X86_64_RELOC_BRANCH" :
                            relocation_info->r_type == X86_64_RELOC_GOT_LOAD ? @"X86_64_RELOC_GOT_LOAD" :
                            relocation_info->r_type == X86_64_RELOC_GOT ? @"X86_64_RELOC_GOT" :
                            relocation_info->r_type == X86_64_RELOC_SUBTRACTOR ? @"X86_64_RELOC_SUBTRACTOR" :
                            relocation_info->r_type == X86_64_RELOC_SIGNED_1 ? @"X86_64_RELOC_SIGNED_1" :
                            relocation_info->r_type == X86_64_RELOC_SIGNED_2 ? @"X86_64_RELOC_SIGNED_2" :
                            relocation_info->r_type == X86_64_RELOC_SIGNED_4 ? @"X86_64_RELOC_SIGNED_4" : @"?????"];
    }
    else if (mach_header_64->cputype == CPU_TYPE_ARM64)
    {
      [node.details appendRow:@"":@"":@"Type"
                             :relocation_info->r_type == ARM64_RELOC_UNSIGNED ? @"ARM64_RELOC_UNSIGNED" :
                              relocation_info->r_type == ARM64_RELOC_SUBTRACTOR ? @"ARM64_RELOC_SUBTRACTOR" :
                              relocation_info->r_type == ARM64_RELOC_BRANCH26 ? @"ARM64_RELOC_BRANCH26" :
                              relocation_info->r_type == ARM64_RELOC_PAGE21 ? @"ARM64_RELOC_PAGE21" :
                              relocation_info->r_type == ARM64_RELOC_PAGEOFF12 ? @"ARM64_RELOC_PAGEOFF12" :
                              relocation_info->r_type == ARM64_RELOC_GOT_LOAD_PAGE21 ? @"ARM64_RELOC_GOT_LOAD_PAGE21" :
                              relocation_info->r_type == ARM64_RELOC_GOT_LOAD_PAGEOFF12 ? @"ARM64_RELOC_GOT_LOAD_PAGEOFF12" :
                              relocation_info->r_type == ARM64_RELOC_POINTER_TO_GOT ? @"ARM64_RELOC_POINTER_TO_GOT" :
                              relocation_info->r_type == ARM64_RELOC_TLVP_LOAD_PAGE21 ? @"ARM64_RELOC_TLVP_LOAD_PAGE21" :
                              relocation_info->r_type == ARM64_RELOC_TLVP_LOAD_PAGEOFF12 ? @"ARM64_RELOC_TLVP_LOAD_PAGEOFF12" :
                              relocation_info->r_type == ARM64_RELOC_ADDEND ? @"ARM64_RELOC_ADDEND" : @"?????"];
    }
    
    if (relocation_info)
    {
      [node.details appendRow:@"":@"":@"External"
                             :relocation_info->r_extern ? @"True" : @"False"];
    }
    
    [node.details appendRow:@"":@"":@"PCRelative"
                           :relocation_info->r_pcrel ? @"True" : @"False"];
    
    [node.details appendRow:@"":@"":@"Length"
                           :[NSString stringWithFormat:@"%u", relocLength]];
    
    [node.details setAttributesFromRowIndex:bookmark:MVMetaDataAttributeName,symbolName,
                                                      MVCellColorAttributeName,color,nil];
    [node.details setAttributes:MVUnderlineAttributeName,@"YES",nil];
  } // loop relocs
  
  return node;
}

//-----------------------------------------------------------------------------
- (MVNode *) createSymbolsNode:parent 
                       caption:(NSString *)caption
                      location:(uint32_t)location
                        length:(uint32_t)length
{
  MVNodeSaver nodeSaver;
  MVNode * node = [parent insertChildWithDetails:caption location:location length:length saver:nodeSaver]; 
  
  NSRange range = NSMakeRange(location,0);
  NSString * lastReadHex;
  
  for (uint32_t nsym = 0; nsym < length / sizeof(struct nlist); ++nsym)
  {
    if ([backgroundThread isCancelled]) break;
    
    MATCH_STRUCT(nlist, location + nsym * sizeof(struct nlist))
    
    // accumulate search info
    NSUInteger bookmark = node.details.rowCount;
    NSString * symbolName = NSSTRING(strtab + nlist->n_un.n_strx);
    NSColor * color = nil;
    
    /* print the symbol nr */
    [node.details appendRow:[NSString stringWithFormat:@"#%d", nsym]
                           :@""
                           :@""
                           :@""];
      
    [dataController read_uint32:range lastReadHex:&lastReadHex];
    [node.details appendRow:[NSString stringWithFormat:@"%.8lX", range.location]
                           :lastReadHex
                           :@"String Table Index"
                           :symbolName];
    
    [dataController read_uint8:range lastReadHex:&lastReadHex];
    [node.details appendRow:[NSString stringWithFormat:@"%.8lX", range.location]
                           :lastReadHex
                           :@"Type"
                           :@""];
    
    if (nlist->n_type & N_STAB)
    {
      [node.details appendRow:@"":@"":@"E0":@"N_STAB"];
      color = [NSColor magentaColor];
    }
    else
    {
      switch (nlist->n_type & N_TYPE)
      {
        case N_UNDF:  [node.details appendRow:@"":@"":@"00":@"N_UNDF"]; break;
        case N_ABS:   [node.details appendRow:@"":@"":@"02":@"N_ABS"]; break;
        case N_SECT:  [node.details appendRow:@"":@"":@"0E":@"N_SECT"]; break;
        case N_PBUD:  [node.details appendRow:@"":@"":@"0C":@"N_PBUD"]; break;
        case N_INDR:  [node.details appendRow:@"":@"":@"0A":@"N_INDR"]; break;
      }
      
      if (nlist->n_type & N_PEXT) [node.details appendRow:@"":@"":@"10":@"N_PEXT"];
      if (nlist->n_type & N_EXT)  [node.details appendRow:@"":@"":@"01":@"N_EXT"];
      
      if (nlist->n_type & N_EXT) color = ((nlist->n_type & N_TYPE) == N_UNDF || (nlist->n_type & N_TYPE) == N_PBUD 
                                          ? [NSColor greenColor] : [NSColor orangeColor]);
    }
    
    struct section const * section = [self getSectionByIndex:nlist->n_sect];
    
    [dataController read_uint8:range lastReadHex:&lastReadHex];
    [node.details appendRow:[NSString stringWithFormat:@"%.8lX", range.location]
                           :lastReadHex
                           :@"Section Index"
                           :nlist->n_sect == NO_SECT ? @"NO_SECT" 
                              : [NSString stringWithFormat:@"%u (%s,%s)", 
                                 nlist->n_sect,
                                 string(section->segname,16).c_str(),
                                 string(section->sectname,16).c_str()]];
    
    [dataController read_uint16:range lastReadHex:&lastReadHex];
    [node.details appendRow:[NSString stringWithFormat:@"%.8lX", range.location]
                           :lastReadHex
                           :@"Description"
                           :@""];
    
    if ((nlist->n_type & N_STAB) == 0 && 
        ((nlist->n_type & N_TYPE) == N_UNDF || (nlist->n_type & N_TYPE) == N_PBUD) &&
        (nlist->n_type & N_EXT))
    {
      switch (nlist->n_desc & REFERENCE_TYPE)
      {
        case REFERENCE_FLAG_UNDEFINED_NON_LAZY:         [node.details appendRow:@"":@"":@"0":@"REFERENCE_FLAG_UNDEFINED_NON_LAZY"]; break;
        case REFERENCE_FLAG_UNDEFINED_LAZY:             [node.details appendRow:@"":@"":@"1":@"REFERENCE_FLAG_UNDEFINED_LAZY"]; break;
        case REFERENCE_FLAG_DEFINED:                    [node.details appendRow:@"":@"":@"2":@"REFERENCE_FLAG_DEFINED"]; break;
        case REFERENCE_FLAG_PRIVATE_DEFINED:            [node.details appendRow:@"":@"":@"3":@"REFERENCE_FLAG_PRIVATE_DEFINED"]; break;
        case REFERENCE_FLAG_PRIVATE_UNDEFINED_NON_LAZY: [node.details appendRow:@"":@"":@"4":@"REFERENCE_FLAG_PRIVATE_UNDEFINED_NON_LAZY"]; break;
        case REFERENCE_FLAG_PRIVATE_UNDEFINED_LAZY:     [node.details appendRow:@"":@"":@"5":@"REFERENCE_FLAG_PRIVATE_UNDEFINED_LAZY"]; break;
        default: 
          [node.details appendRow:@"":@"":[NSString stringWithFormat:@"%u",nlist->n_desc & REFERENCE_TYPE]:@"???"]; break;
      }
      
      uint32_t libOrdinal = GET_LIBRARY_ORDINAL(nlist->n_desc);
      struct dylib const * dylib = [self getDylibByIndex:libOrdinal];
      
      [node.details appendRow:@"":@"":@"Library Ordinal"
                             :[NSString stringWithFormat:@"%u (%@)",libOrdinal,
                               libOrdinal == SELF_LIBRARY_ORDINAL ? @"SELF_LIBRARY_ORDINAL" :
                               libOrdinal == DYNAMIC_LOOKUP_ORDINAL ? @"DYNAMIC_LOOKUP_ORDINAL" :
                               libOrdinal == EXECUTABLE_ORDINAL ? @"EXECUTABLE_ORDINAL" :
                               [NSSTRING((uint8_t *)dylib + dylib->name.offset - sizeof(struct load_command)) lastPathComponent]]];
    }
    
    if ((nlist->n_desc & N_ARM_THUMB_DEF) == N_ARM_THUMB_DEF)               [node.details appendRow:@"":@"":@"0008":@"N_ARM_THUMB_DEF"];
    if ((nlist->n_desc & REFERENCED_DYNAMICALLY) == REFERENCED_DYNAMICALLY) [node.details appendRow:@"":@"":@"0010":@"REFERENCED_DYNAMICALLY"];
    if ((nlist->n_desc & N_NO_DEAD_STRIP) == N_NO_DEAD_STRIP)               [node.details appendRow:@"":@"":@"0020":@"N_NO_DEAD_STRIP"];
    if ((nlist->n_desc & N_WEAK_REF) == N_WEAK_REF)                         [node.details appendRow:@"":@"":@"0040":@"N_WEAK_REF"];

    if ((nlist->n_type & N_TYPE) == N_UNDF)
    {
      if ((nlist->n_desc & N_REF_TO_WEAK) == N_REF_TO_WEAK)                 [node.details appendRow:@"":@"":@"0080":@"N_REF_TO_WEAK"];
    }
    else
    {
      if ((nlist->n_desc & N_WEAK_DEF) == N_WEAK_DEF)                       [node.details appendRow:@"":@"":@"0080":@"N_WEAK_DEF"];
      if ((nlist->n_desc & N_SYMBOL_RESOLVER) == N_SYMBOL_RESOLVER)         [node.details appendRow:@"":@"":@"0100":@"N_SYMBOL_RESOLVER"];
    }
    
    [dataController read_uint32:range lastReadHex:&lastReadHex];
    if ((nlist->n_type & N_TYPE) == N_SECT)
    {
      [node.details appendRow:[NSString stringWithFormat:@"%.8lX", range.location]
                             :lastReadHex
                             :@"Value"
                             :(nlist->n_type & N_STAB) || section == NULL
                                ? [NSString stringWithFormat:@"%u", nlist->n_value] : nlist->n_value == 0 ? @"0"
                                : [NSString stringWithFormat:@"%u ($+%u)", nlist->n_value, nlist->n_value - section->addr]];
      
      // fill in lookup table with defined sybols
      if ((nlist->n_type & N_STAB) == 0)
      {
        // it is possible to associate more than one symbol to the same address.
        // every new symbol will be appended to the list
        
        NSString * nameToStore = [symbolNames objectForKey:[NSNumber numberWithUnsignedLong:nlist->n_value]];
        nameToStore = (nameToStore != nil 
                       ? [nameToStore stringByAppendingFormat:@"(%@)", symbolName] 
                       : [NSString stringWithFormat:@"0x%X (%@)", nlist->n_value, symbolName]);
        if(nameToStore){
             [symbolNames setObject:nameToStore
                              forKey:[NSNumber numberWithUnsignedLong:nlist->n_value]];
        }
      }
    } 
    else
    {
      [node.details appendRow:[NSString stringWithFormat:@"%.8lX", range.location]
                             :lastReadHex
                             :@"Value"
                             :[NSString stringWithFormat:@"%u", nlist->n_value]];
      
      // fill in lookup table with undefined sybols (key equals (-1) * index)
      uint32_t key = *symbols.begin() - nlist - 1;
      if(symbolName){
        [symbolNames setObject:symbolName
                            forKey:[NSNumber numberWithUnsignedLong:key]];
      }
    }

    [node.details setAttributesFromRowIndex:bookmark:MVMetaDataAttributeName,symbolName,
                                                      MVCellColorAttributeName,color,nil];
    [node.details setAttributes:MVUnderlineAttributeName,@"YES",nil];
  } // loop

  return node;
}

//-----------------------------------------------------------------------------
- (MVNode *) createSymbols64Node:parent 
                         caption:(NSString *)caption
                        location:(uint32_t)location
                          length:(uint32_t)length
{
  MVNodeSaver nodeSaver;
  MVNode * node = [parent insertChildWithDetails:caption location:location length:length saver:nodeSaver]; 
  
  NSRange range = NSMakeRange(location,0);
  NSString * lastReadHex;
  
  for (uint32_t nsym = 0; nsym < length / sizeof(struct nlist_64); ++nsym)
  {
    if ([backgroundThread isCancelled]) break;
    
    MATCH_STRUCT(nlist_64, location + nsym * sizeof(struct nlist_64))
    
    // accumulate search info
    NSUInteger bookmark = node.details.rowCount;
    NSString * symbolName = NSSTRING(strtab + nlist_64->n_un.n_strx);
    NSColor * color = nil;
    
    /* print the symbol nr */
    [node.details appendRow:[NSString stringWithFormat:@"#%d", nsym]
                           :@""
                           :@""
                           :@""];

    [dataController read_uint32:range lastReadHex:&lastReadHex];
    [node.details appendRow:[NSString stringWithFormat:@"%.8lX", range.location]
                           :lastReadHex
                           :@"String Table Index"
                           :symbolName];
    
    [dataController read_uint8:range lastReadHex:&lastReadHex];
    [node.details appendRow:[NSString stringWithFormat:@"%.8lX", range.location]
                           :lastReadHex
                           :@"Type"
                           :@""];
    
    if (nlist_64->n_type & N_STAB)
    {
      [node.details appendRow:@"":@"":@"E0":@"N_STAB"];
      color = [NSColor magentaColor];
    }
    else
    {
      switch (nlist_64->n_type & N_TYPE)
      {
        case N_UNDF:  [node.details appendRow:@"":@"":@"00":@"N_UNDF"]; break;
        case N_ABS:   [node.details appendRow:@"":@"":@"02":@"N_ABS"]; break;
        case N_SECT:  [node.details appendRow:@"":@"":@"0E":@"N_SECT"]; break;
        case N_PBUD:  [node.details appendRow:@"":@"":@"0C":@"N_PBUD"]; break;
        case N_INDR:  [node.details appendRow:@"":@"":@"0A":@"N_INDR"]; break;
      }
      
      if (nlist_64->n_type & N_PEXT) [node.details appendRow:@"":@"":@"10":@"N_PEXT"];
      if (nlist_64->n_type & N_EXT)  [node.details appendRow:@"":@"":@"01":@"N_EXT"];
      
      if (nlist_64->n_type & N_EXT) color = ((nlist_64->n_type & N_TYPE) == N_UNDF || (nlist_64->n_type & N_TYPE) == N_PBUD 
                                             ? [NSColor greenColor] : [NSColor orangeColor]);
    }
    
    struct section_64 const * section_64 = [self getSection64ByIndex:nlist_64->n_sect];
    
    [dataController read_uint8:range lastReadHex:&lastReadHex];
    [node.details appendRow:[NSString stringWithFormat:@"%.8lX", range.location]
                           :lastReadHex
                           :@"Section Index"
                           :nlist_64->n_sect == NO_SECT ? @"NO_SECT" 
                              : [NSString stringWithFormat:@"%u (%s,%s)", 
                                 nlist_64->n_sect,
                                 string(section_64->segname,16).c_str(),
                                 string(section_64->sectname,16).c_str()]];
    
    [dataController read_uint16:range lastReadHex:&lastReadHex];
    [node.details appendRow:[NSString stringWithFormat:@"%.8lX", range.location]
                           :lastReadHex
                           :@"Description"
                           :@""];
    
    if ((nlist_64->n_type & N_STAB) == 0 && 
        ((nlist_64->n_type & N_TYPE) == N_UNDF || (nlist_64->n_type & N_TYPE) == N_PBUD) &&
        (nlist_64->n_type & N_EXT))
    {
      switch (nlist_64->n_desc & REFERENCE_TYPE)
      {
        case REFERENCE_FLAG_UNDEFINED_NON_LAZY:         [node.details appendRow:@"":@"":@"0":@"REFERENCE_FLAG_UNDEFINED_NON_LAZY"]; break;
        case REFERENCE_FLAG_UNDEFINED_LAZY:             [node.details appendRow:@"":@"":@"1":@"REFERENCE_FLAG_UNDEFINED_LAZY"]; break;
        case REFERENCE_FLAG_DEFINED:                    [node.details appendRow:@"":@"":@"2":@"REFERENCE_FLAG_DEFINED"]; break;
        case REFERENCE_FLAG_PRIVATE_DEFINED:            [node.details appendRow:@"":@"":@"3":@"REFERENCE_FLAG_PRIVATE_DEFINED"]; break;
        case REFERENCE_FLAG_PRIVATE_UNDEFINED_NON_LAZY: [node.details appendRow:@"":@"":@"4":@"REFERENCE_FLAG_PRIVATE_UNDEFINED_NON_LAZY"]; break;
        case REFERENCE_FLAG_PRIVATE_UNDEFINED_LAZY:     [node.details appendRow:@"":@"":@"5":@"REFERENCE_FLAG_PRIVATE_UNDEFINED_LAZY"]; break;
        default:
          [node.details appendRow:@"":@"":[NSString stringWithFormat:@"%u",nlist_64->n_desc & REFERENCE_TYPE]:@"???"]; break;
      }
      
      uint32_t libOrdinal = GET_LIBRARY_ORDINAL(nlist_64->n_desc);
      struct dylib const * dylib = [self getDylibByIndex:libOrdinal];
      
      [node.details appendRow:@"":@"":@"Library Ordinal"
                             :[NSString stringWithFormat:@"%u (%@)",libOrdinal,
                               libOrdinal == SELF_LIBRARY_ORDINAL ? @"SELF_LIBRARY_ORDINAL" :
                               libOrdinal == DYNAMIC_LOOKUP_ORDINAL ? @"DYNAMIC_LOOKUP_ORDINAL" :
                               libOrdinal == EXECUTABLE_ORDINAL ? @"EXECUTABLE_ORDINAL" :
                               [NSSTRING((uint8_t *)dylib + dylib->name.offset - sizeof(struct load_command)) lastPathComponent]]];
    }
    
    if ((nlist_64->n_desc & REFERENCED_DYNAMICALLY) == REFERENCED_DYNAMICALLY)  [node.details appendRow:@"":@"":@"0010":@"REFERENCED_DYNAMICALLY"];
    if ((nlist_64->n_desc & N_NO_DEAD_STRIP) == N_NO_DEAD_STRIP)                [node.details appendRow:@"":@"":@"0020":@"N_NO_DEAD_STRIP"];
    if ((nlist_64->n_desc & N_WEAK_REF) == N_WEAK_REF)                          [node.details appendRow:@"":@"":@"0040":@"N_WEAK_REF"];
    if ((nlist_64->n_desc & N_WEAK_DEF) == N_WEAK_DEF)                          [node.details appendRow:@"":@"":@"0080":
                                                                                 (nlist_64->n_type & N_TYPE) == N_UNDF || (nlist_64->n_type & N_TYPE) == N_PBUD 
                                                                                  ? @"N_REF_TO_WEAK" 
                                                                                  : @"N_WEAK_DEF"];
    if ((nlist_64->n_desc & N_SYMBOL_RESOLVER) == N_SYMBOL_RESOLVER)            [node.details appendRow:@"":@"":@"0100":@"N_SYMBOL_RESOLVER"];
    
    [dataController read_uint64:range lastReadHex:&lastReadHex];
    if ((nlist_64->n_type & N_TYPE) == N_SECT)
    {
      [node.details appendRow:[NSString stringWithFormat:@"%.8lX", range.location]
                             :lastReadHex
                             :@"Value"
                             :(nlist_64->n_type & N_STAB) || section_64 == NULL
                                ? [NSString stringWithFormat:@"%qu", nlist_64->n_value] : nlist_64->n_value == 0 ? @"0"
                                : [NSString stringWithFormat:@"%qu ($+%qu)", nlist_64->n_value, nlist_64->n_value - section_64->addr]];
      
      // fill in lookup table with defined sybols
      if ((nlist_64->n_type & N_STAB) == 0)
      {
        // it is possible to associate more than one symbol to the same address.
        // every new symbol will be appended to the list

        NSString * nameToStore = [symbolNames objectForKey:[NSNumber numberWithUnsignedLongLong:nlist_64->n_value]];
        nameToStore = (nameToStore != nil 
                       ? [nameToStore stringByAppendingFormat:@"(%@)", symbolName] 
                       : [NSString stringWithFormat:@"0x%qX (%@)", nlist_64->n_value, symbolName]);
        if(nameToStore){
          [symbolNames setObject:nameToStore
                              forKey:[NSNumber numberWithUnsignedLongLong:nlist_64->n_value]];
        }
      }
    } 
    else
    {
      [node.details appendRow:[NSString stringWithFormat:@"%.8lX", range.location]
                             :lastReadHex
                             :@"Value"
                             :[NSString stringWithFormat:@"%qu", nlist_64->n_value]];
      
      // fill in lookup table with undefined sybols (key equals (-1) * index)
      uint64_t key = *symbols_64.begin() - nlist_64 - 1;
      if(symbolName){
        [symbolNames setObject:symbolName
                            forKey:[NSNumber numberWithUnsignedLongLong:key]];
      }
    }
    
    [node.details setAttributesFromRowIndex:bookmark:MVMetaDataAttributeName,symbolName,
                                                      MVCellColorAttributeName,color,nil];
    [node.details setAttributes:MVUnderlineAttributeName,@"YES",nil];
  } // loop
  
  return node;
}

//-----------------------------------------------------------------------------
- (MVNode *) createReferencesNode:parent 
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
    MATCH_STRUCT(dylib_reference, NSMaxRange(range))
    
    if (dylib_reference->isym >= symbols.size())
    {
      [NSException raise:@"Symbol"
                  format:@"index is out of range %u", dylib_reference->isym];
    }
    
    // accumulate search info
    NSUInteger bookmark = node.details.rowCount;
    NSString * symbolName = NSSTRING(strtab + [self getSymbolByIndex:dylib_reference->isym]->n_un.n_strx);
    
    [dataController read_uint32:range lastReadHex:&lastReadHex];
    [node.details appendRow:[NSString stringWithFormat:@"%.8lX", range.location]
                           :lastReadHex
                           :@"Symbol"
                           :symbolName];
    
    [node.details appendRow:@"":@"":@"Flags":@""];
    
    switch (dylib_reference->flags)
    {
      case REFERENCE_FLAG_UNDEFINED_NON_LAZY:         [node.details appendRow:@"":@"":@"0":@"REFERENCE_FLAG_UNDEFINED_NON_LAZY"]; break;
      case REFERENCE_FLAG_UNDEFINED_LAZY:             [node.details appendRow:@"":@"":@"1":@"REFERENCE_FLAG_UNDEFINED_LAZY"]; break;
      case REFERENCE_FLAG_DEFINED:                    [node.details appendRow:@"":@"":@"2":@"REFERENCE_FLAG_DEFINED"]; break;
      case REFERENCE_FLAG_PRIVATE_DEFINED:            [node.details appendRow:@"":@"":@"3":@"REFERENCE_FLAG_PRIVATE_DEFINED"]; break;
      case REFERENCE_FLAG_PRIVATE_UNDEFINED_NON_LAZY: [node.details appendRow:@"":@"":@"4":@"REFERENCE_FLAG_PRIVATE_UNDEFINED_NON_LAZY"]; break;
      case REFERENCE_FLAG_PRIVATE_UNDEFINED_LAZY:     [node.details appendRow:@"":@"":@"5":@"REFERENCE_FLAG_PRIVATE_UNDEFINED_LAZY"]; break;
      default:
        [node.details appendRow:@"":@"":[NSString stringWithFormat:@"%u",dylib_reference->flags]:@"???"]; break;
    }
    
    [node.details setAttributesFromRowIndex:bookmark:MVMetaDataAttributeName,symbolName,nil];
    [node.details setAttributes:MVUnderlineAttributeName,@"YES",nil];
  }
  
  
  return node;
}

//-----------------------------------------------------------------------------
- (MVNode *) createISymbolsNode:parent
                        caption:(NSString *)caption
                       location:(uint32_t)location
                         length:(uint32_t)length
{
  MVNodeSaver nodeSaver;
  MVNode * node = [parent insertChildWithDetails:caption location:location length:length saver:nodeSaver]; 
  
  NSRange range = NSMakeRange(location,0);
  NSString * lastReadHex;
  
  for (uint32_t nindsym = 0; nindsym < length / sizeof(uint32_t); ++nindsym)
  {
    uint32_t nsect = sections.size();
    while (--nsect > 0)
    {
      struct section const * section = [self getSectionByIndex:nsect];
      
      if (((section->flags & SECTION_TYPE) != S_SYMBOL_STUBS &&
           (section->flags & SECTION_TYPE) != S_LAZY_SYMBOL_POINTERS &&
           (section->flags & SECTION_TYPE) != S_LAZY_DYLIB_SYMBOL_POINTERS &&
           (section->flags & SECTION_TYPE) != S_NON_LAZY_SYMBOL_POINTERS) ||
          section->reserved1 > nindsym)
      {
        // section type or indirect symbol index mismatch
        continue;
      }
      
      // preserve location of indirect symbol index for further processing
      isymbols.push_back((uint32_t *)[self imageAt:location + sizeof(uint32_t)*nindsym]);

      // calculate stub or pointer length
      uint32_t length = (section->reserved2 > 0 ? section->reserved2 : sizeof(uint32_t));
        
      // calculate indirect value location
      uint32_t indirectAddress = section->addr + (nindsym - section->reserved1) * length;
        
      // accumulate search info
      NSUInteger bookmark = node.details.rowCount;
      NSString * symbolName = nil;
      NSColor * color = nil;
        
      // read indirect symbol index
      uint32_t indirectIndex = [dataController read_uint32:range lastReadHex:&lastReadHex];
        
      if ((indirectIndex & (INDIRECT_SYMBOL_LOCAL | INDIRECT_SYMBOL_ABS)) == 0)
      {
        if (indirectIndex >= symbols.size())
        {
          [NSException raise:@"Symbol"
                      format:@"index is out of range %u", indirectIndex];
        }
          
        symbolName = NSSTRING(strtab + [self getSymbolByIndex:indirectIndex]->n_un.n_strx);
          
        [node.details appendRow:[NSString stringWithFormat:@"%.8lX", range.location]
                               :lastReadHex
                               :@"Symbol"
                               :symbolName];
          
        // fill in lookup table with indirect sybols
        [symbolNames setObject:[NSString stringWithFormat:@"[%@->%@]",
                                [self findSymbolAtRVA:indirectAddress],symbolName]
                        forKey:[NSNumber numberWithUnsignedLong:indirectAddress]];
      }
      else
      {
        [node.details appendRow:[NSString stringWithFormat:@"%.8lX", range.location]
                               :lastReadHex
                               :@"Symbol"
                               :@""];
          
        switch (indirectIndex)
        {
          case INDIRECT_SYMBOL_LOCAL:
          {
            [node.details appendRow:@"":@"":@"80000000":@"INDIRECT_SYMBOL_LOCAL"];
            color = [NSColor magentaColor];
            
            // follow indirection for pointers only
            NSRange range = NSMakeRange(indirectAddress - section->addr + section->offset + imageOffset, 0);
            uint32_t targetAddress = [dataController read_uint32:range lastReadHex:&lastReadHex];
            [node.details appendRow:@"":@"":@"Target":(symbolName = [self findSymbolAtRVA:targetAddress])];
            symbolName = [NSString stringWithFormat:@"[%@->%@]",
                          [self findSymbolAtRVA:indirectAddress],symbolName];
          } break;

          case INDIRECT_SYMBOL_ABS:
          {
            [node.details appendRow:@"":@"":@"40000000":@"INDIRECT_SYMBOL_ABS"];
            color = [NSColor greenColor];
            symbolName = [NSString stringWithFormat:@"[0x%X->ABSOLUTE]",indirectAddress];
          } break;

          default:
          {
            [node.details appendRow:@"":@"":@"80000000":@"INDIRECT_SYMBOL_LOCAL"];
            [node.details appendRow:@"":@"":@"40000000":@"INDIRECT_SYMBOL_ABS"];
            color = [NSColor orangeColor];
            symbolName = [NSString stringWithFormat:@"[0x%X->LOCAL ABSOLUTE]",indirectAddress];
          }
        }
        if(symbolName){
          // fill in lookup table with special indirect sybols
          [symbolNames setObject:symbolName
                              forKey:[NSNumber numberWithUnsignedLong:indirectAddress]];
        }
      }
        
      [node.details appendRow:@"":@"":@"Section"
                             :[NSString stringWithFormat:@"(%s,%s)", 
                               string(section->segname,16).c_str(),
                               string(section->sectname,16).c_str()]];
        
      [node.details appendRow:@"":@"":@"Indirect Address"
                             :[NSString stringWithFormat:@"0x%X ($+%u)", indirectAddress, indirectAddress - section->addr]];
      
      [node.details setAttributesFromRowIndex:bookmark:MVMetaDataAttributeName,symbolName,
                                                        MVCellColorAttributeName,color,nil];
      [node.details setAttributes:MVUnderlineAttributeName,@"YES",nil];
      break; // we have found the section we was looking for

    } // loop sections
  } // loop indirect symbols
  
  return node;
}

//-----------------------------------------------------------------------------
- (MVNode *) createISymbols64Node:parent
                          caption:(NSString *)caption
                         location:(uint32_t)location
                           length:(uint32_t)length
{
  MVNodeSaver nodeSaver;
  MVNode * node = [parent insertChildWithDetails:caption location:location length:length saver:nodeSaver]; 
  
  NSRange range = NSMakeRange(location,0);
  NSString * lastReadHex;
  
  for (uint32_t nindsym = 0; nindsym < length / sizeof(uint32_t); ++nindsym)
  {
    uint32_t nsect = sections_64.size();
    while (--nsect > 0)
    {
      struct section_64 const * section_64 = [self getSection64ByIndex:nsect];
      
      if (((section_64->flags & SECTION_TYPE) != S_SYMBOL_STUBS &&
           (section_64->flags & SECTION_TYPE) != S_LAZY_SYMBOL_POINTERS &&
           (section_64->flags & SECTION_TYPE) != S_LAZY_DYLIB_SYMBOL_POINTERS &&
           (section_64->flags & SECTION_TYPE) != S_NON_LAZY_SYMBOL_POINTERS) ||
          section_64->reserved1 > nindsym)
      {
        // section type or indirect symbol index mismatch
        continue;
      }
      
      // preserve location of indirect symbol index for further processing
      isymbols.push_back((uint32_t *)[self imageAt:location + sizeof(uint32_t)*nindsym]);

      // calculate stub or pointer length
      uint32_t length = (section_64->reserved2 > 0 ? section_64->reserved2 : sizeof(uint64_t));
        
      // calculate indirect value location
      uint64_t indirectAddress = section_64->addr + (nindsym - section_64->reserved1) * length;
        
      // accumulate search info
      NSUInteger bookmark = node.details.rowCount;
      NSString * symbolName = nil;
      NSColor * color = nil;
      
      // read indirect symbol index
      uint32_t indirectIndex = [dataController read_uint32:range lastReadHex:&lastReadHex];
      
      if ((indirectIndex & (INDIRECT_SYMBOL_LOCAL | INDIRECT_SYMBOL_ABS)) == 0)
      {
        if (indirectIndex >= symbols_64.size())
        {
          [NSException raise:@"Symbol"
                      format:@"index is out of range %u", indirectIndex];
        }
        
        symbolName = NSSTRING(strtab + [self getSymbol64ByIndex:indirectIndex]->n_un.n_strx);
        
        [node.details appendRow:[NSString stringWithFormat:@"%.8lX", range.location]
                               :lastReadHex
                               :@"Symbol"
                               :symbolName];
        
        // fill in lookup table with indirect sybols
        [symbolNames setObject:[NSString stringWithFormat:@"[%@->%@]",
                                [self findSymbolAtRVA64:indirectAddress],symbolName]
                        forKey:[NSNumber numberWithUnsignedLongLong:indirectAddress]];
      }
      else
      {
        [node.details appendRow:[NSString stringWithFormat:@"%.8lX", range.location]
                               :lastReadHex
                               :@"Symbol"
                               :@""];
        
        switch (indirectIndex)
        {
          case INDIRECT_SYMBOL_LOCAL:
          {
            [node.details appendRow:@"":@"":@"80000000":@"INDIRECT_SYMBOL_LOCAL"];
            color = [NSColor magentaColor];
            
            // follow indirection for pointers only
            NSRange range = NSMakeRange(indirectAddress - section_64->addr + section_64->offset + imageOffset, 0);
            uint64_t targetAddress = [dataController read_uint64:range lastReadHex:&lastReadHex];
            [node.details appendRow:@"":@"":@"Target":(symbolName = [self findSymbolAtRVA64:targetAddress])];
            symbolName = [NSString stringWithFormat:@"[%@->%@]",
                          [self findSymbolAtRVA64:indirectAddress],symbolName];
          } break;
            
          case INDIRECT_SYMBOL_ABS:
          {
            [node.details appendRow:@"":@"":@"40000000":@"INDIRECT_SYMBOL_ABS"];
            color = [NSColor greenColor];
            symbolName = [NSString stringWithFormat:@"[0x%qX->ABSOLUTE]",indirectAddress];
          } break;
            
          default:
          {
            [node.details appendRow:@"":@"":@"80000000":@"INDIRECT_SYMBOL_LOCAL"];
            [node.details appendRow:@"":@"":@"40000000":@"INDIRECT_SYMBOL_ABS"];
            color = [NSColor orangeColor];
            symbolName = [NSString stringWithFormat:@"[0x%qX->LOCAL ABSOLUTE]",indirectAddress];
          }
        }
        
        if(symbolName){
        // fill in lookup table with special indirect sybols
          [symbolNames setObject:symbolName
                              forKey:[NSNumber numberWithUnsignedLongLong:indirectAddress]];
        }
      }
      
      [node.details appendRow:@"":@"":@"Section"
                             :[NSString stringWithFormat:@"(%s,%s)", 
                               string(section_64->segname,16).c_str(),
                               string(section_64->sectname,16).c_str()]];
      
      [node.details appendRow:@"":@"":@"Indirect Address"
                             :[NSString stringWithFormat:@"0x%qX ($+%qu)", indirectAddress, indirectAddress - section_64->addr]];
      
      [node.details setAttributesFromRowIndex:bookmark:MVMetaDataAttributeName,symbolName,
                                                        MVCellColorAttributeName,color,nil];
      [node.details setAttributes:MVUnderlineAttributeName,@"YES",nil];
      break;  // we have found the section we was looking for
      
    } // loop sections
  } // loop indirect symbols

  return node;
}

//-----------------------------------------------------------------------------
- (MVNode *) createTOCNode:parent
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
    MATCH_STRUCT(dylib_table_of_contents, NSMaxRange(range))
    
    if (dylib_table_of_contents->symbol_index >= symbols.size())
    {
      [NSException raise:@"Symbol"
                  format:@"index is out of range %u", dylib_table_of_contents->symbol_index];
    }

    if (dylib_table_of_contents->module_index >= modules.size())
    {
      [NSException raise:@"Module"
                  format:@"index is out of range %u", dylib_table_of_contents->module_index];
    }
    
    // accumulate search info
    NSUInteger bookmark = node.details.rowCount;
    NSString * symbolName = NSSTRING(strtab + [self getSymbolByIndex:dylib_table_of_contents->symbol_index]->n_un.n_strx); 
    
    [dataController read_uint32:range lastReadHex:&lastReadHex];
    [node.details appendRow:[NSString stringWithFormat:@"%.8lX", range.location]
                           :lastReadHex
                           :@"Symbol"
                           :symbolName];
    
    [dataController read_uint32:range lastReadHex:&lastReadHex];
    [node.details appendRow:[NSString stringWithFormat:@"%.8lX", range.location]
                           :lastReadHex
                           :@"Module"
                           :NSSTRING(strtab + modules.at(dylib_table_of_contents->module_index)->module_name)];    

    [node.details setAttributesFromRowIndex:bookmark:MVMetaDataAttributeName,symbolName,nil];
    [node.details setAttributes:MVUnderlineAttributeName,@"YES",nil];
  }
  
  return node;
}

//-----------------------------------------------------------------------------
- (MVNode *) createTOC64Node:parent
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
    MATCH_STRUCT(dylib_table_of_contents, NSMaxRange(range))
    
    if (dylib_table_of_contents->symbol_index >= symbols_64.size())
    {
      [NSException raise:@"Symbol"
                  format:@"index is out of range %u", dylib_table_of_contents->symbol_index];
    }
    
    if (dylib_table_of_contents->module_index >= modules_64.size())
    {
      [NSException raise:@"Module"
                  format:@"index is out of range %u", dylib_table_of_contents->module_index];
    }
    
    // accumulate search info
    NSUInteger bookmark = node.details.rowCount;
    NSString * symbolName = NSSTRING(strtab + [self getSymbol64ByIndex:dylib_table_of_contents->symbol_index]->n_un.n_strx); 
    
    [dataController read_uint32:range lastReadHex:&lastReadHex];
    [node.details appendRow:[NSString stringWithFormat:@"%.8lX", range.location]
                           :lastReadHex
                           :@"Symbol"
                           :symbolName];
    
    [dataController read_uint32:range lastReadHex:&lastReadHex];
    [node.details appendRow:[NSString stringWithFormat:@"%.8lX", range.location]
                           :lastReadHex
                           :@"Module"
                           :NSSTRING(strtab + modules_64.at(dylib_table_of_contents->module_index)->module_name)];    

    [node.details setAttributesFromRowIndex:bookmark:MVMetaDataAttributeName,symbolName,nil];
    [node.details setAttributes:MVUnderlineAttributeName,@"YES",nil];
  }
  
  return node;
}

//-----------------------------------------------------------------------------
- (MVNode *) createModulesNode:parent
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
    MATCH_STRUCT(dylib_module, NSMaxRange(range))
    modules.push_back(dylib_module);
    
    // accumulate search info
    NSUInteger bookmark = node.details.rowCount;
    NSString * moduleName = NSSTRING(strtab + dylib_module->module_name); 
    
    [dataController read_uint32:range lastReadHex:&lastReadHex];
    [node.details appendRow:[NSString stringWithFormat:@"%.8lX", range.location]
                           :lastReadHex
                           :@"Module"
                           :moduleName];
    
    [dataController read_uint32:range lastReadHex:&lastReadHex];
    [node.details appendRow:[NSString stringWithFormat:@"%.8lX", range.location]
                           :lastReadHex
                           :@"Ext Defined Symbols Index"
                           :[NSString stringWithFormat:@"%u", dylib_module->iextdefsym]];
    
    [dataController read_uint32:range lastReadHex:&lastReadHex];
    [node.details appendRow:[NSString stringWithFormat:@"%.8lX", range.location]
                           :lastReadHex
                           :@"Ext Defined Symbols Number"
                           :[NSString stringWithFormat:@"%u", dylib_module->nextdefsym]];
    
    [dataController read_uint32:range lastReadHex:&lastReadHex];
    [node.details appendRow:[NSString stringWithFormat:@"%.8lX", range.location]
                           :lastReadHex
                           :@"Ext References Index"
                           :[NSString stringWithFormat:@"%u", dylib_module->irefsym]];
    
    [dataController read_uint32:range lastReadHex:&lastReadHex];
    [node.details appendRow:[NSString stringWithFormat:@"%.8lX", range.location]
                           :lastReadHex
                           :@"Ext References Number"
                           :[NSString stringWithFormat:@"%u", dylib_module->nrefsym]];
    
    [dataController read_uint32:range lastReadHex:&lastReadHex];
    [node.details appendRow:[NSString stringWithFormat:@"%.8lX", range.location]
                           :lastReadHex
                           :@"Local Symbols Index"
                           :[NSString stringWithFormat:@"%u", dylib_module->ilocalsym]];
    
    [dataController read_uint32:range lastReadHex:&lastReadHex];
    [node.details appendRow:[NSString stringWithFormat:@"%.8lX", range.location]
                           :lastReadHex
                           :@"Local Symbols Number"
                           :[NSString stringWithFormat:@"%u", dylib_module->nlocalsym]];
    
    [dataController read_uint32:range lastReadHex:&lastReadHex];
    [node.details appendRow:[NSString stringWithFormat:@"%.8lX", range.location]
                           :lastReadHex
                           :@"Ext Relocs Index"
                           :[NSString stringWithFormat:@"%u", dylib_module->iextrel]];
    
    [dataController read_uint32:range lastReadHex:&lastReadHex];
    [node.details appendRow:[NSString stringWithFormat:@"%.8lX", range.location]
                           :lastReadHex
                           :@"Ext Relocs Number"
                           :[NSString stringWithFormat:@"%u", dylib_module->nextrel]];
    
    [dataController read_uint32:range lastReadHex:&lastReadHex];
    [node.details appendRow:[NSString stringWithFormat:@"%.8lX", range.location]
                           :lastReadHex
                           :@"Init Pointers Index"
                           :[NSString stringWithFormat:@"%u", dylib_module->iinit_iterm & 0xfff]];
    
    [node.details appendRow:@"":@"":@"Term Pointers Index"
                           :[NSString stringWithFormat:@"%u", (dylib_module->iinit_iterm >> 16) & 0xffff]];
    
    [dataController read_uint32:range lastReadHex:&lastReadHex];
    [node.details appendRow:[NSString stringWithFormat:@"%.8lX", range.location]
                           :lastReadHex
                           :@"Init Pointers Number"
                           :[NSString stringWithFormat:@"%u", dylib_module->ninit_nterm & 0xffff]];
    
    [node.details appendRow:@"":@"":@"Term Pointers Number"
                           :[NSString stringWithFormat:@"%u", (dylib_module->ninit_nterm >> 16) & 0xffff]];
    
    [dataController read_uint32:range lastReadHex:&lastReadHex];
    [node.details appendRow:[NSString stringWithFormat:@"%.8lX", range.location]
                           :lastReadHex
                           :@"Module Info Address"
                           :[NSString stringWithFormat:@"0x%X", dylib_module->objc_module_info_addr]];
    
    [dataController read_uint32:range lastReadHex:&lastReadHex];
    [node.details appendRow:[NSString stringWithFormat:@"%.8lX", range.location]
                           :lastReadHex
                           :@"Module Info Size"
                           :[NSString stringWithFormat:@"%u", dylib_module->objc_module_info_size]];
    
    [node.details setAttributesFromRowIndex:bookmark:MVMetaDataAttributeName,moduleName,nil];
    [node.details setAttributes:MVUnderlineAttributeName,@"YES",nil];
  }
  
  return node;
}

//-----------------------------------------------------------------------------
- (MVNode *) createModules64Node:parent
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
    MATCH_STRUCT(dylib_module_64, NSMaxRange(range))
    modules_64.push_back(dylib_module_64);
    
    // accumulate search info
    NSUInteger bookmark = node.details.rowCount;
    NSString * moduleName = NSSTRING(strtab + dylib_module_64->module_name); 
    
    [dataController read_uint32:range lastReadHex:&lastReadHex];
    [node.details appendRow:[NSString stringWithFormat:@"%.8lX", range.location]
                           :lastReadHex
                           :@"Module"
                           :moduleName];
    
    [dataController read_uint32:range lastReadHex:&lastReadHex];
    [node.details appendRow:[NSString stringWithFormat:@"%.8lX", range.location]
                           :lastReadHex
                           :@"Ext Defined Symbols Index"
                           :[NSString stringWithFormat:@"%u", dylib_module_64->iextdefsym]];
    
    [dataController read_uint32:range lastReadHex:&lastReadHex];
    [node.details appendRow:[NSString stringWithFormat:@"%.8lX", range.location]
                           :lastReadHex
                           :@"Ext Defined Symbols Number"
                           :[NSString stringWithFormat:@"%u", dylib_module_64->nextdefsym]];
    
    [dataController read_uint32:range lastReadHex:&lastReadHex];
    [node.details appendRow:[NSString stringWithFormat:@"%.8lX", range.location]
                           :lastReadHex
                           :@"Ext References Index"
                           :[NSString stringWithFormat:@"%u", dylib_module_64->irefsym]];
    
    [dataController read_uint32:range lastReadHex:&lastReadHex];
    [node.details appendRow:[NSString stringWithFormat:@"%.8lX", range.location]
                           :lastReadHex
                           :@"Ext References Number"
                           :[NSString stringWithFormat:@"%u", dylib_module_64->nrefsym]];
    
    [dataController read_uint32:range lastReadHex:&lastReadHex];
    [node.details appendRow:[NSString stringWithFormat:@"%.8lX", range.location]
                           :lastReadHex
                           :@"Local Symbols Index"
                           :[NSString stringWithFormat:@"%u", dylib_module_64->ilocalsym]];
    
    [dataController read_uint32:range lastReadHex:&lastReadHex];
    [node.details appendRow:[NSString stringWithFormat:@"%.8lX", range.location]
                           :lastReadHex
                           :@"Local Symbols Number"
                           :[NSString stringWithFormat:@"%u", dylib_module_64->nlocalsym]];
    
    [dataController read_uint32:range lastReadHex:&lastReadHex];
    [node.details appendRow:[NSString stringWithFormat:@"%.8lX", range.location]
                           :lastReadHex
                           :@"Ext Relocs Index"
                           :[NSString stringWithFormat:@"%u", dylib_module_64->iextrel]];
    
    [dataController read_uint32:range lastReadHex:&lastReadHex];
    [node.details appendRow:[NSString stringWithFormat:@"%.8lX", range.location]
                           :lastReadHex
                           :@"Ext Relocs Number"
                           :[NSString stringWithFormat:@"%u", dylib_module_64->nextrel]];
    
    [dataController read_uint32:range lastReadHex:&lastReadHex];
    [node.details appendRow:[NSString stringWithFormat:@"%.8lX", range.location]
                           :lastReadHex
                           :@"Init Pointers Index"
                           :[NSString stringWithFormat:@"%u", dylib_module_64->iinit_iterm & 0xfff]];
    
    [node.details appendRow:@"":@"":@"Term Pointers Index"
                           :[NSString stringWithFormat:@"%u", (dylib_module_64->iinit_iterm >> 16) & 0xffff]];
    
    [dataController read_uint32:range lastReadHex:&lastReadHex];
    [node.details appendRow:[NSString stringWithFormat:@"%.8lX", range.location]
                           :lastReadHex
                           :@"Init Pointers Number"
                           :[NSString stringWithFormat:@"%u", dylib_module_64->ninit_nterm & 0xffff]];
    
    [node.details appendRow:@"":@"":@"Term Pointers Number"
                           :[NSString stringWithFormat:@"%u", (dylib_module_64->ninit_nterm >> 16) & 0xffff]];
    
    [dataController read_uint32:range lastReadHex:&lastReadHex];
    [node.details appendRow:[NSString stringWithFormat:@"%.8lX", range.location]
                           :lastReadHex
                           :@"Module Info Address"
                           :[NSString stringWithFormat:@"0x%llX", dylib_module_64->objc_module_info_addr]];
    
    [dataController read_uint64:range lastReadHex:&lastReadHex];
    [node.details appendRow:[NSString stringWithFormat:@"%.8lX", range.location]
                           :lastReadHex
                           :@"Module Info Size"
                           :[NSString stringWithFormat:@"%u", dylib_module_64->objc_module_info_size]];
    
    [node.details setAttributesFromRowIndex:bookmark:MVMetaDataAttributeName,moduleName,nil];
    [node.details setAttributes:MVUnderlineAttributeName,@"YES",nil];
  }
  
  return node;
}

//-----------------------------------------------------------------------------
- (MVNode *) createTwoLevelHintsNode:parent 
                             caption:(NSString *)caption
                            location:(uint32_t)location
                              length:(uint32_t)length
                               index:(uint32_t)index
{
  MVNodeSaver nodeSaver;
  MVNode * node = [parent insertChildWithDetails:caption location:location length:length saver:nodeSaver]; 
  
  NSRange range = NSMakeRange(location,0);
  NSString * lastReadHex;

  while (NSMaxRange(range) < location + length)
  {
    MATCH_STRUCT(twolevel_hint, NSMaxRange(range))
    
    [dataController read_uint32:range lastReadHex:&lastReadHex];
    [node.details appendRow:[NSString stringWithFormat:@"%.8lX", range.location]
                           :lastReadHex
                           :@"Subimage"
                           :[NSString stringWithFormat:@"%u", twolevel_hint->isub_image]];

    uint32_t libOrdinal = GET_LIBRARY_ORDINAL([self is64bit] == NO 
                                               ? [self getSymbolByIndex:index]->n_desc
                                               : [self getSymbol64ByIndex:index]->n_desc);
    struct dylib const * dylib = [self getDylibByIndex:libOrdinal];

    NSString * symbolName = [NSString stringWithFormat:@"%s (from %@)",
                             strtab +([self is64bit] == NO 
                                        ? [self getSymbolByIndex:index]->n_un.n_strx
                                        : [self getSymbol64ByIndex:index]->n_un.n_strx),
                             (libOrdinal == SELF_LIBRARY_ORDINAL ? @"SELF_LIBRARY_ORDINAL" :
                              libOrdinal == DYNAMIC_LOOKUP_ORDINAL ? @"DYNAMIC_LOOKUP_ORDINAL" :
                              libOrdinal == EXECUTABLE_ORDINAL ? @"EXECUTABLE_ORDINAL" :
                              [NSSTRING((uint8_t *)dylib + dylib->name.offset - sizeof(struct load_command)) lastPathComponent])];
    ++index;
    
    [node.details appendRow:@"":@"":@"TOC Index"
                           :[NSString stringWithFormat:@"%u %@", twolevel_hint->itoc, symbolName]];
    
    [node.details setAttributes:MVMetaDataAttributeName,symbolName,
                                MVUnderlineAttributeName,@"YES",nil];
  }
    
  return node;
}

//-----------------------------------------------------------------------------
- (MVNode *) createSplitSegmentNode:parent
                            caption:(NSString *)caption
                           location:(uint32_t)location
                             length:(uint32_t)length
                        baseAddress:(uint64_t)baseAddress
{
  MVNodeSaver nodeSaver;
  MVNode * node = [parent insertChildWithDetails:caption location:location length:length saver:nodeSaver]; 
  
  NSRange range = NSMakeRange(location,0);
  NSString * lastReadHex;
  NSString * symbolName = nil;

  while (NSMaxRange(range) < location + length)
  {    
    uint8_t kind = [dataController read_uint8:range lastReadHex:&lastReadHex];
    
    if (kind == 0) // terminator
    {
      break;
    }
    
    [node.details appendRow:[NSString stringWithFormat:@"%.8lX", range.location]
                           :lastReadHex
                           :@"kind"
                           :kind == 1 ? @"32-bit pointer" :
                            kind == 2 ? @"64-bit pointer" :
                            kind == 3 ? @"ppc hi16" :
                            kind == 4 ? @"32-bit offset to IMPORT" :
                            kind == 5 ? @"thumb2 movw" :
                            kind == 6 ? @"ARM movw" :
                            kind == 0x10 ? @"thumb2 movt low high 4 bits=0" :
                            kind == 0x11 ? @"thumb2 movt low high 4 bits=1" :
                            kind == 0x12 ? @"thumb2 movt low high 4 bits=2" :
                            kind == 0x13 ? @"thumb2 movt low high 4 bits=3" :
                            kind == 0x14 ? @"thumb2 movt low high 4 bits=4" :
                            kind == 0x15 ? @"thumb2 movt low high 4 bits=5" :
                            kind == 0x16 ? @"thumb2 movt low high 4 bits=6" :
                            kind == 0x17 ? @"thumb2 movt low high 4 bits=7" :
                            kind == 0x18 ? @"thumb2 movt low high 4 bits=8" :
                            kind == 0x19 ? @"thumb2 movt low high 4 bits=9" :
                            kind == 0x1A ? @"thumb2 movt low high 4 bits=0xA" :
                            kind == 0x1B ? @"thumb2 movt low high 4 bits=0xB" :
                            kind == 0x1C ? @"thumb2 movt low high 4 bits=0xC" :
                            kind == 0x1D ? @"thumb2 movt low high 4 bits=0xD" :
                            kind == 0x1E ? @"thumb2 movt low high 4 bits=0xE" :
                            kind == 0x1f ? @"thumb2 movt low high 4 bits=0xF" : @"???"];
    
    [node.details setAttributes:MVCellColorAttributeName,[NSColor greenColor],nil];
    
    uint64_t address = baseAddress;
    uint64_t offset = 0;
    do
    {
      offset = [dataController read_uleb128:range lastReadHex:&lastReadHex];
      address += offset;
      
      [node.details appendRow:[NSString stringWithFormat:@"%.8lX", range.location]
                             :lastReadHex
                             :@"uleb128"
                             :[NSString stringWithFormat:@"%@ %@",
                               [self is64bit] == NO ? [self findSectionContainsRVA:address] : [self findSectionContainsRVA64:address],
                               (symbolName = [self is64bit] == NO ? [self findSymbolAtRVA:(uint32_t)address] : [self findSymbolAtRVA64:address])]];
      
      [node.details setAttributes:MVMetaDataAttributeName,symbolName,nil]; 
      
    } while (offset != 0);
    
    [node.details setAttributes:MVUnderlineAttributeName,@"YES",nil];
  }
  
  return node;
}

//-----------------------------------------------------------------------------
- (MVNode *) createFunctionStartsNode:parent
                              caption:(NSString *)caption
                             location:(uint32_t)location
                               length:(uint32_t)length
                          baseAddress:(uint64_t)baseAddress
{
  MVNodeSaver nodeSaver;
  MVNode * node = [parent insertChildWithDetails:caption location:location length:length saver:nodeSaver]; 
  
  uint64_t address = baseAddress;
  
  NSRange range = NSMakeRange(location,0);
  NSString * lastReadHex;
  NSString * symbolName = nil;
  
  while (NSMaxRange(range) < location + length)
  {    
    uint64_t offset = [dataController read_uleb128:range lastReadHex:&lastReadHex];
    address += offset;
    
    [node.details appendRow:[NSString stringWithFormat:@"%.8lX", range.location]
                           :lastReadHex
                           :@"uleb128"
                           :(symbolName = [self is64bit] == NO ? 
                              [self findSymbolAtRVA:(uint32_t)address] :
                              [self findSymbolAtRVA64:address])];

    [node.details setAttributes:MVMetaDataAttributeName,symbolName,nil]; 
  }
  
  return node;
}

//-----------------------------------------------------------------------------
- (MVNode *) createDataInCodeEntriesNode:parent
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
    MATCH_STRUCT(data_in_code_entry, NSMaxRange(range))
    dices.push_back(data_in_code_entry);
    
    [dataController read_uint32:range lastReadHex:&lastReadHex];
    [node.details appendRow:[NSString stringWithFormat:@"%.8lX", range.location]
                           :lastReadHex
                           :@"Offset"
                           :[self findSymbolAtRVA:[self fileOffsetToRVA:data_in_code_entry->offset + imageOffset]]];

    [dataController read_uint16:range lastReadHex:&lastReadHex];
    [node.details appendRow:[NSString stringWithFormat:@"%.8lX", range.location]
                           :lastReadHex
                           :@"Length"
                           :[NSString stringWithFormat:@"%u", (uint32_t)data_in_code_entry->length]];

    [dataController read_uint16:range lastReadHex:&lastReadHex];
    [node.details appendRow:[NSString stringWithFormat:@"%.8lX", range.location]
                           :lastReadHex
                           :@"Kind"
                           :data_in_code_entry->kind == DICE_KIND_DATA ? @"DICE_KIND_DATA" :
                            data_in_code_entry->kind == DICE_KIND_JUMP_TABLE8 ? @"DICE_KIND_JUMP_TABLE8" :
                            data_in_code_entry->kind == DICE_KIND_JUMP_TABLE16 ? @"DICE_KIND_JUMP_TABLE16" :
                            data_in_code_entry->kind == DICE_KIND_JUMP_TABLE32 ? @"DICE_KIND_JUMP_TABLE32" :
                            data_in_code_entry->kind == DICE_KIND_ABS_JUMP_TABLE32 ? @"DICE_KIND_ABS_JUMP_TABLE32" : @"???"];
    
    [node.details setAttributes:MVUnderlineAttributeName,@"YES",nil];
  }
  
  return node;
}

@end
