/*
 *  MachOLayout.h
 *  MachOView
 *
 *  Created by psaghelyi on 15/06/2010.
 *
 */

#include <string>
#include <vector>
#include <set>
#include <map>
#include <cxxabi.h>

#import "Layout.h"

typedef std::vector<struct load_command const *>          CommandVector;
typedef std::vector<struct segment_command const *>       SegmentVector;
typedef std::vector<struct segment_command_64 const *>    Segment64Vector;
typedef std::vector<struct section const *>               SectionVector;
typedef std::vector<struct section_64 const *>            Section64Vector;
typedef std::vector<struct nlist const *>                 NListVector;
typedef std::vector<struct nlist_64 const *>              NList64Vector;
typedef std::vector<struct dylib const *>                 DylibVector;
typedef std::vector<struct dylib_module const *>          ModuleVector;
typedef std::vector<struct dylib_module_64 const *>       Module64Vector;
typedef std::vector<struct data_in_code_entry const *>    DataInCodeEntryVector;
typedef std::vector<uint32_t const *>                     IndirectSymbolVector;

typedef std::map<uint32_t,std::pair<uint32_t,uint64_t> >        RelocMap;           // fileOffset --> <length,value>
typedef std::map<uint32_t,std::pair<uint64_t,uint64_t> >        SegmentInfoMap;     // fileOffset --> <address,size>
typedef std::map<uint64_t,std::pair<uint32_t,NSDictionary * __weak> >  SectionInfoMap;  // address    --> <fileOffset,sectionUserInfo>
typedef std::map<uint64_t,uint64_t>                             ExceptionFrameMap;  // LSDA_addr  --> PCBegin_addr

@interface MachOLayout : MVLayout 
{
  uint64_t                entryPoint;       // instruction pointer in thread command
  
  CommandVector           commands;         // load commands
  SegmentVector           segments;         // segment entries for 32-bit architectures
  Segment64Vector         segments_64;      // segment entries for 64-bit architectures
  SectionVector           sections;         // section entries for 32-bit architectures
  Section64Vector         sections_64;      // section entries for 64-bit architectures
  NListVector             symbols;          // symbol entries in the symbol table for 32-bit architectures
  NList64Vector           symbols_64;       // symbol entries in the symbol table for 64-bit architectures
  IndirectSymbolVector    isymbols;         // indirect symbols
  
  DylibVector             dylibs;           // imported dynamic libraries
  ModuleVector            modules;          // module table entries in a dynamic shared library for 32-bit architectures
  Module64Vector          modules_64;       // module table entries in a dynamic shared library for 64-bit architectures
  DataInCodeEntryVector   dices;            // data in code entries
  char const *            strtab;           // pointer to the string table
  
  //RelocMap                relocMap;         // section relocations
  SegmentInfoMap          segmentInfo;      // segment info lookup table by offset
  SectionInfoMap          sectionInfo;      // section info lookup table by address
  ExceptionFrameMap       lsdaInfo;         // LSDA info lookup table by address
  
  NSMutableDictionary *   symbolNames;      // symbol names by address
}

+ (MachOLayout *)layoutWithDataController:(MVDataController *)dc rootNode:(MVNode *)node;

- (struct section const *)getSectionByIndex:(uint32_t)index;
- (struct section_64 const *)getSection64ByIndex:(uint32_t)index;

- (struct nlist const *)getSymbolByIndex:(uint32_t)index;
- (struct nlist_64 const *)getSymbol64ByIndex:(uint32_t)index;

- (struct dylib const *)getDylibByIndex:(uint32_t)index;

- (NSDictionary *)userInfoForSection:(struct section const *)section;
- (NSDictionary *)userInfoForSection64:(struct section_64 const *)section_64;

- (MVNode *)sectionNodeContainsRVA:(uint32_t)rva;
- (MVNode *)sectionNodeContainsRVA64:(uint64_t)rva;

- (NSString *)findSectionContainsRVA:(uint32_t)rva;
- (NSString *)findSectionContainsRVA64:(uint64_t)rva64;

- (NSString *)findSymbolAtRVA:(uint32_t)rva;
- (NSString *)findSymbolAtRVA64:(uint64_t)rva64;

- (uint32_t)fileOffsetToRVA:(uint32_t)offset;
- (uint64_t)fileOffsetToRVA64:(uint32_t)offset;

- (uint32_t)RVAToFileOffset:(uint32_t)rva;
- (uint32_t)RVA64ToFileOffset:(uint64_t)rva64;

- (void)addRelocAtFileOffset:(uint32_t)offset withLength:(uint32_t)length andValue:(uint64_t)value;

- (BOOL)isDylibStub;

@end
