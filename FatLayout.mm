/*
 *  FatLayout.mm
 *  MachOView
 *
 *  Created by psaghelyi on 02/12/2011.
 *
 */

#import "Common.h"
#import "FatLayout.h"
#import "DataController.h"
#import "MachOLayout.h"
#import "ReadWrite.h"

using namespace std;

//============================================================================
@implementation FatLayout

//-----------------------------------------------------------------------------
- (id)initWithDataController:(MVDataController *)dc rootNode:(MVNode *)node
{
  if (self = [super initWithDataController:dc rootNode:node])
  {
    //further initialisations 
  }
  return self;
}

//-----------------------------------------------------------------------------
+ (FatLayout *)layoutWithDataController:(MVDataController *)dc rootNode:(MVNode *)node
{
  return [[FatLayout alloc] initWithDataController:dc rootNode:node];
}

//----------------------------------------------------------------------------
- (MVNode *)createHeaderNode:(MVNode *)parent
                     caption:(NSString *)caption
                    location:(uint32_t)location
                  fat_header:(struct fat_header const *)fat_header
{
  MVNodeSaver nodeSaver;
  MVNode * node = [parent insertChildWithDetails:caption 
                                        location:location 
                                          length:sizeof(struct fat_header) + fat_header->nfat_arch * sizeof(struct fat_arch)
                                           saver:nodeSaver]; 

  NSRange range = NSMakeRange(location,0);
  NSString * lastReadHex;

  uint32_t magic = [self read_uint32:range lastReadHex:&lastReadHex];
  [node.details appendRow:[NSString stringWithFormat:@"%.8lX", range.location]
                         :lastReadHex
                         :@"Magic Number"
                         :magic == FAT_MAGIC ? @"FAT_MAGIC" :
                          magic == FAT_CIGAM ? @"FAT_CIGAM" : @"???"];

  [node.details setAttributes:MVCellColorAttributeName,[NSColor greenColor],nil];

  [self read_uint32:range lastReadHex:&lastReadHex];
  [node.details appendRow:[NSString stringWithFormat:@"%.8lX", range.location]
                         :lastReadHex
                         :@"Number of Architecture"
                         :[NSString stringWithFormat:@"%u",fat_header->nfat_arch]];
  
  [node.details setAttributes:MVCellColorAttributeName,[NSColor greenColor],
                              MVUnderlineAttributeName,@"YES",nil];
  
  for (uint32_t nimg = 0; nimg < fat_header->nfat_arch; ++nimg)
  {      
    // need to make copy for byte swapping
    struct fat_arch fat_arch;
    [dataController.fileData getBytes:&fat_arch range:NSMakeRange(NSMaxRange(range), sizeof(struct fat_arch))];
    swap_fat_arch(&fat_arch, 1, NX_LittleEndian);
    
    [self read_uint32:range lastReadHex:&lastReadHex];
    [node.details appendRow:[NSString stringWithFormat:@"%.8lX", range.location]
                           :lastReadHex
                           :@"CPU Type"
                           :fat_arch.cputype == CPU_TYPE_ANY ? @"CPU_TYPE_ANY" :
                            fat_arch.cputype == CPU_TYPE_I386 ? @"CPU_TYPE_I386" :
                            fat_arch.cputype == CPU_TYPE_X86_64 ? @"CPU_TYPE_X86_64" :
                            fat_arch.cputype == CPU_TYPE_ARM ? @"CPU_TYPE_ARM" :
                            fat_arch.cputype == CPU_TYPE_POWERPC ? @"CPU_TYPE_POWERPC" : 
                            fat_arch.cputype == CPU_TYPE_POWERPC64 ? @"CPU_TYPE_POWERPC64" : 
                            @"???"];
    
    [self read_uint32:range lastReadHex:&lastReadHex];
    [node.details appendRow:[NSString stringWithFormat:@"%.8lX", range.location]
                           :lastReadHex
                           :@"CPU SubType"
                           :fat_arch.cputype == CPU_TYPE_POWERPC ?
                            ((fat_arch.cpusubtype & ~CPU_SUBTYPE_MASK) == CPU_SUBTYPE_POWERPC_ALL ? @"CPU_SUBTYPE_POWERPC_ALL" :
                             (fat_arch.cpusubtype & ~CPU_SUBTYPE_MASK) == CPU_SUBTYPE_POWERPC_601 ? @"CPU_SUBTYPE_POWERPC_601" :
                             (fat_arch.cpusubtype & ~CPU_SUBTYPE_MASK) == CPU_SUBTYPE_POWERPC_602 ? @"CPU_SUBTYPE_POWERPC_602" :
                             (fat_arch.cpusubtype & ~CPU_SUBTYPE_MASK) == CPU_SUBTYPE_POWERPC_603 ? @"CPU_SUBTYPE_POWERPC_603" :
                             (fat_arch.cpusubtype & ~CPU_SUBTYPE_MASK) == CPU_SUBTYPE_POWERPC_603e ? @"CPU_SUBTYPE_POWERPC_603e" :
                             (fat_arch.cpusubtype & ~CPU_SUBTYPE_MASK) == CPU_SUBTYPE_POWERPC_603ev ? @"CPU_SUBTYPE_POWERPC_603ev" :
                             (fat_arch.cpusubtype & ~CPU_SUBTYPE_MASK) == CPU_SUBTYPE_POWERPC_604 ? @"CPU_SUBTYPE_POWERPC_604" :
                             (fat_arch.cpusubtype & ~CPU_SUBTYPE_MASK) == CPU_SUBTYPE_POWERPC_604e ? @"CPU_SUBTYPE_POWERPC_604e" :
                             (fat_arch.cpusubtype & ~CPU_SUBTYPE_MASK) == CPU_SUBTYPE_POWERPC_620 ? @"CPU_SUBTYPE_POWERPC_620" :
                             (fat_arch.cpusubtype & ~CPU_SUBTYPE_MASK) == CPU_SUBTYPE_POWERPC_750 ? @"CPU_SUBTYPE_POWERPC_750" :
                             (fat_arch.cpusubtype & ~CPU_SUBTYPE_MASK) == CPU_SUBTYPE_POWERPC_7400 ? @"CPU_SUBTYPE_POWERPC_7400" :
                             (fat_arch.cpusubtype & ~CPU_SUBTYPE_MASK) == CPU_SUBTYPE_POWERPC_7450 ? @"CPU_SUBTYPE_POWERPC_7450" :
                             (fat_arch.cpusubtype & ~CPU_SUBTYPE_MASK) == CPU_SUBTYPE_POWERPC_970 ? @"CPU_SUBTYPE_POWERPC_970" : @"???") :
                            fat_arch.cputype == CPU_TYPE_ARM ?
                            ((fat_arch.cpusubtype & ~CPU_SUBTYPE_MASK) == CPU_SUBTYPE_ARM_ALL ? @"CPU_SUBTYPE_ARM_ALL" : 
                             (fat_arch.cpusubtype & ~CPU_SUBTYPE_MASK) == CPU_SUBTYPE_ARM_V4T ? @"CPU_SUBTYPE_ARM_V4T" : 
                             (fat_arch.cpusubtype & ~CPU_SUBTYPE_MASK) == CPU_SUBTYPE_ARM_V6 ? @"CPU_SUBTYPE_ARM_V6" : 
                             (fat_arch.cpusubtype & ~CPU_SUBTYPE_MASK) == CPU_SUBTYPE_ARM_V5TEJ ? @"CPU_SUBTYPE_ARM_V5TEJ" : 
                             (fat_arch.cpusubtype & ~CPU_SUBTYPE_MASK) == CPU_SUBTYPE_ARM_XSCALE ? @"CPU_SUBTYPE_ARM_XSCALE" : 
                             (fat_arch.cpusubtype & ~CPU_SUBTYPE_MASK) == CPU_SUBTYPE_ARM_V7 ? @"CPU_SUBTYPE_ARM_V7" :
                             (fat_arch.cpusubtype & ~CPU_SUBTYPE_MASK) == CPU_SUBTYPE_ARM_V7F ? @"CPU_SUBTYPE_ARM_V7F" :
                             (fat_arch.cpusubtype & ~CPU_SUBTYPE_MASK) == CPU_SUBTYPE_ARM_V7S ? @"CPU_SUBTYPE_ARM_V7S" :
                             (fat_arch.cpusubtype & ~CPU_SUBTYPE_MASK) == CPU_SUBTYPE_ARM_V7K ? @"CPU_SUBTYPE_ARM_V7K" : @"???") :
                            fat_arch.cputype == CPU_TYPE_X86 ?
                            ((fat_arch.cpusubtype & ~CPU_SUBTYPE_MASK) == CPU_SUBTYPE_X86_ALL ? @"CPU_SUBTYPE_X86_ALL" : @"???") :
                            fat_arch.cputype == CPU_TYPE_X86_64 ?
                            ((fat_arch.cpusubtype & ~CPU_SUBTYPE_MASK) == CPU_SUBTYPE_X86_64_ALL ? @"CPU_SUBTYPE_X86_64_ALL" : @"???") : 
                             @"???"];
    
    [self read_uint32:range lastReadHex:&lastReadHex];
    [node.details appendRow:[NSString stringWithFormat:@"%.8lX", range.location]
                           :lastReadHex
                           :@"Offset"
                           :[NSString stringWithFormat:@"%u",fat_arch.offset]];
    
    [self read_uint32:range lastReadHex:&lastReadHex];
    [node.details appendRow:[NSString stringWithFormat:@"%.8lX", range.location]
                           :lastReadHex
                           :@"Size"
                           :[NSString stringWithFormat:@"%u",fat_arch.size]];
    
    [self read_uint32:range lastReadHex:&lastReadHex];
    [node.details appendRow:[NSString stringWithFormat:@"%.8lX", range.location]
                           :lastReadHex
                           :@"Align"
                           :[NSString stringWithFormat:@"%u",(1 << fat_arch.align)]];
                           
    [node.details setAttributes:MVUnderlineAttributeName,@"YES",nil];
  }
  
  return node;
}

//----------------------------------------------------------------------------
- (void)doMainTasks
{
  struct fat_header fat_header;
  [dataController.fileData getBytes:&fat_header length:sizeof(struct fat_header)];
  
  if (fat_header.magic == FAT_CIGAM)
  {
    swap_fat_header(&fat_header, NX_LittleEndian);
  }
  
  [self createHeaderNode:rootNode 
                 caption:@"Fat Header"
                location:imageOffset 
              fat_header:&fat_header];
  
  [super doMainTasks];
}

@end

