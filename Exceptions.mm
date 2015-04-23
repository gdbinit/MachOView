/*
 *  Exceptions.mm
 *  MachOView
 *
 *  Created by psaghelyi on 20/07/2010.
 *
 */

#include <string>
#include <vector>
#include <set>
#include <map>

#import "Exceptions.h"
#import "ReadWrite.h"
#import "DataController.h"

using namespace std;

#define DW_EH_PE_absptr		0x00
#define DW_EH_PE_omit     0xff

#define DW_EH_PE_uleb128	0x01
#define DW_EH_PE_udata2		0x02
#define DW_EH_PE_udata4		0x03
#define DW_EH_PE_udata8		0x04
#define DW_EH_PE_sleb128	0x09
#define DW_EH_PE_sdata2		0x0A
#define DW_EH_PE_sdata4		0x0B
#define DW_EH_PE_sdata8		0x0C
#define DW_EH_PE_signed		0x08

#define DW_EH_PE_pcrel		0x10
#define DW_EH_PE_textrel	0x20
#define DW_EH_PE_datarel	0x30
#define DW_EH_PE_funcrel	0x40
#define DW_EH_PE_aligned	0x50

#define DW_EH_PE_indirect	0x80

//============================================================================
@implementation MachOLayout (Exceptions)

//-----------------------------------------------------------------------------
- (NSString *)getNameForEncoding:(uint8_t)format
{
  switch (format)
  {
    case DW_EH_PE_absptr: return @"absolute";
    case DW_EH_PE_omit: return @"omit";
    case DW_EH_PE_aligned: return @"aligned absolute";
      
    case DW_EH_PE_uleb128: return @"uleb128";
    case DW_EH_PE_udata2: return @"udata2";
    case DW_EH_PE_udata4: return @"udata4";
    case DW_EH_PE_udata8: return @"udata8";
    case DW_EH_PE_sleb128: return @"sleb128";
    case DW_EH_PE_sdata2: return @"sdata2";
    case DW_EH_PE_sdata4: return @"sdata4";
    case DW_EH_PE_sdata8: return @"sdata8";
      
    case DW_EH_PE_absptr | DW_EH_PE_pcrel: return @"pcrel";
    case DW_EH_PE_uleb128 | DW_EH_PE_pcrel: return @"pcrel uleb128";
    case DW_EH_PE_udata2 | DW_EH_PE_pcrel: return @"pcrel udata2";
    case DW_EH_PE_udata4 | DW_EH_PE_pcrel: return @"pcrel udata4";
    case DW_EH_PE_udata8 | DW_EH_PE_pcrel: return @"pcrel udata8";
    case DW_EH_PE_sleb128 | DW_EH_PE_pcrel: return @"pcrel sleb128";
    case DW_EH_PE_sdata2 | DW_EH_PE_pcrel: return @"pcrel sdata2";
    case DW_EH_PE_sdata4 | DW_EH_PE_pcrel: return @"pcrel sdata4";
    case DW_EH_PE_sdata8 | DW_EH_PE_pcrel: return @"pcrel sdata8";
      
    case DW_EH_PE_absptr | DW_EH_PE_textrel: return @"textrel";
    case DW_EH_PE_uleb128 | DW_EH_PE_textrel: return @"textrel uleb128";
    case DW_EH_PE_udata2 | DW_EH_PE_textrel: return @"textrel udata2";
    case DW_EH_PE_udata4 | DW_EH_PE_textrel: return @"textrel udata4";
    case DW_EH_PE_udata8 | DW_EH_PE_textrel: return @"textrel udata8";
    case DW_EH_PE_sleb128 | DW_EH_PE_textrel: return @"textrel sleb128";
    case DW_EH_PE_sdata2 | DW_EH_PE_textrel: return @"textrel sdata2";
    case DW_EH_PE_sdata4 | DW_EH_PE_textrel: return @"textrel sdata4";
    case DW_EH_PE_sdata8 | DW_EH_PE_textrel: return @"textrel sdata8";
      
    case DW_EH_PE_absptr | DW_EH_PE_datarel: return @"datarel";
    case DW_EH_PE_uleb128 | DW_EH_PE_datarel: return @"datarel uleb128";
    case DW_EH_PE_udata2 | DW_EH_PE_datarel: return @"datarel udata2";
    case DW_EH_PE_udata4 | DW_EH_PE_datarel: return @"datarel udata4";
    case DW_EH_PE_udata8 | DW_EH_PE_datarel: return @"datarel udata8";
    case DW_EH_PE_sleb128 | DW_EH_PE_datarel: return @"datarel sleb128";
    case DW_EH_PE_sdata2 | DW_EH_PE_datarel: return @"datarel sdata2";
    case DW_EH_PE_sdata4 | DW_EH_PE_datarel: return @"datarel sdata4";
    case DW_EH_PE_sdata8 | DW_EH_PE_datarel: return @"datarel sdata8";
      
    case DW_EH_PE_absptr | DW_EH_PE_funcrel: return @"funcrel";
    case DW_EH_PE_uleb128 | DW_EH_PE_funcrel: return @"funcrel uleb128";
    case DW_EH_PE_udata2 | DW_EH_PE_funcrel: return @"funcrel udata2";
    case DW_EH_PE_udata4 | DW_EH_PE_funcrel: return @"funcrel udata4";
    case DW_EH_PE_udata8 | DW_EH_PE_funcrel: return @"funcrel udata8";
    case DW_EH_PE_sleb128 | DW_EH_PE_funcrel: return @"funcrel sleb128";
    case DW_EH_PE_sdata2 | DW_EH_PE_funcrel: return @"funcrel sdata2";
    case DW_EH_PE_sdata4 | DW_EH_PE_funcrel: return @"funcrel sdata4";
    case DW_EH_PE_sdata8 | DW_EH_PE_funcrel: return @"funcrel sdata8";
      
    case DW_EH_PE_indirect | DW_EH_PE_absptr | DW_EH_PE_pcrel: return @"indirect pcrel";
    case DW_EH_PE_indirect | DW_EH_PE_uleb128 | DW_EH_PE_pcrel: return @"indirect pcrel uleb128";
    case DW_EH_PE_indirect | DW_EH_PE_udata2 | DW_EH_PE_pcrel: return @"indirect pcrel udata2";
    case DW_EH_PE_indirect | DW_EH_PE_udata4 | DW_EH_PE_pcrel: return @"indirect pcrel udata4";
    case DW_EH_PE_indirect | DW_EH_PE_udata8 | DW_EH_PE_pcrel: return @"indirect pcrel udata8";
    case DW_EH_PE_indirect | DW_EH_PE_sleb128 | DW_EH_PE_pcrel: return @"indirect pcrel sleb128";
    case DW_EH_PE_indirect | DW_EH_PE_sdata2 | DW_EH_PE_pcrel: return @"indirect pcrel sdata2";
    case DW_EH_PE_indirect | DW_EH_PE_sdata4 | DW_EH_PE_pcrel: return @"indirect pcrel sdata4";
    case DW_EH_PE_indirect | DW_EH_PE_sdata8 | DW_EH_PE_pcrel: return @"indirect pcrel sdata8";
      
    case DW_EH_PE_indirect | DW_EH_PE_absptr | DW_EH_PE_textrel: return @"indirect textrel";
    case DW_EH_PE_indirect | DW_EH_PE_uleb128 | DW_EH_PE_textrel: return @"indirect textrel uleb128";
    case DW_EH_PE_indirect | DW_EH_PE_udata2 | DW_EH_PE_textrel: return @"indirect textrel udata2";
    case DW_EH_PE_indirect | DW_EH_PE_udata4 | DW_EH_PE_textrel: return @"indirect textrel udata4";
    case DW_EH_PE_indirect | DW_EH_PE_udata8 | DW_EH_PE_textrel: return @"indirect textrel udata8";
    case DW_EH_PE_indirect | DW_EH_PE_sleb128 | DW_EH_PE_textrel: return @"indirect textrel sleb128";
    case DW_EH_PE_indirect | DW_EH_PE_sdata2 | DW_EH_PE_textrel: return @"indirect textrel sdata2";
    case DW_EH_PE_indirect | DW_EH_PE_sdata4 | DW_EH_PE_textrel: return @"indirect textrel sdata4";
    case DW_EH_PE_indirect | DW_EH_PE_sdata8 | DW_EH_PE_textrel: return @"indirect textrel sdata8";
      
    case DW_EH_PE_indirect | DW_EH_PE_absptr | DW_EH_PE_datarel: return @"indirect datarel";
    case DW_EH_PE_indirect | DW_EH_PE_uleb128 | DW_EH_PE_datarel: return @"indirect datarel uleb128";
    case DW_EH_PE_indirect | DW_EH_PE_udata2 | DW_EH_PE_datarel: return @"indirect datarel udata2";
    case DW_EH_PE_indirect | DW_EH_PE_udata4 | DW_EH_PE_datarel: return @"indirect datarel udata4";
    case DW_EH_PE_indirect | DW_EH_PE_udata8 | DW_EH_PE_datarel: return @"indirect datarel udata8";
    case DW_EH_PE_indirect | DW_EH_PE_sleb128 | DW_EH_PE_datarel: return @"indirect datarel sleb128";
    case DW_EH_PE_indirect | DW_EH_PE_sdata2 | DW_EH_PE_datarel: return @"indirect datarel sdata2";
    case DW_EH_PE_indirect | DW_EH_PE_sdata4 | DW_EH_PE_datarel: return @"indirect datarel sdata4";
    case DW_EH_PE_indirect | DW_EH_PE_sdata8 | DW_EH_PE_datarel: return @"indirect datarel sdata8";
      
    case DW_EH_PE_indirect | DW_EH_PE_absptr | DW_EH_PE_funcrel: return @"indirect funcrel";
    case DW_EH_PE_indirect | DW_EH_PE_uleb128 | DW_EH_PE_funcrel: return @"indirect funcrel uleb128";
    case DW_EH_PE_indirect | DW_EH_PE_udata2 | DW_EH_PE_funcrel: return @"indirect funcrel udata2";
    case DW_EH_PE_indirect | DW_EH_PE_udata4 | DW_EH_PE_funcrel: return @"indirect funcrel udata4";
    case DW_EH_PE_indirect | DW_EH_PE_udata8 | DW_EH_PE_funcrel: return @"indirect funcrel udata8";
    case DW_EH_PE_indirect | DW_EH_PE_sleb128 | DW_EH_PE_funcrel: return @"indirect funcrel sleb128";
    case DW_EH_PE_indirect | DW_EH_PE_sdata2 | DW_EH_PE_funcrel: return @"indirect funcrel sdata2";
    case DW_EH_PE_indirect | DW_EH_PE_sdata4 | DW_EH_PE_funcrel: return @"indirect funcrel sdata4";
    case DW_EH_PE_indirect | DW_EH_PE_sdata8 | DW_EH_PE_funcrel: return @"indirect funcrel sdata8";
  }
  return @"???";
}

#define ENCODING_FIXSIZE(format) \
((format & 0xf) == DW_EH_PE_udata2 || (format & 0xf) == DW_EH_PE_sdata2) ? sizeof(uint16_t) : \
((format & 0xf) == DW_EH_PE_udata4 || (format & 0xf) == DW_EH_PE_sdata4) ? sizeof(uint32_t) : \
((format & 0xf) == DW_EH_PE_udata8 || (format & 0xf) == DW_EH_PE_sdata8) ? sizeof(uint64_t) : \
((format & 0xf) == DW_EH_PE_uleb128 || (format & 0xf) == DW_EH_PE_sleb128) ? 0 : \
([self is64bit] == NO) ? sizeof(uint32_t) : sizeof(uint64_t)

//-----------------------------------------------------------------------------
#define READ_USE_ENCODING(format,range,hexstr) \
  ((format & 0xf) == DW_EH_PE_udata2 || (format & 0xf) == DW_EH_PE_sdata2) ? [dataController read_uint16:range lastReadHex:&hexstr] : \
  ((format & 0xf) == DW_EH_PE_udata4 || (format & 0xf) == DW_EH_PE_sdata4) ? [dataController read_uint32:range lastReadHex:&hexstr] : \
  ((format & 0xf) == DW_EH_PE_udata8 || (format & 0xf) == DW_EH_PE_sdata8) ? [dataController read_uint64:range lastReadHex:&hexstr] : \
  (format & 0xf) == DW_EH_PE_uleb128 ? [dataController read_uleb128:range lastReadHex:&hexstr] : \
  (format & 0xf) == DW_EH_PE_sleb128 ? [dataController read_sleb128:range lastReadHex:&hexstr] : \
  ([self is64bit] == NO) ? [dataController read_uint32:range lastReadHex:&hexstr] : [dataController read_uint64:range lastReadHex:&hexstr]

//-----------------------------------------------------------------------------
- (NSString *)guessSymbolUsingEncoding:(uint8_t)format atOffset:(uint32_t)offset withValue:(uint32_t &)value
{
  NSParameterAssert([self is64bit] == NO);
                    
  if (value == 0)
  {
    return @"0x0";
  }

  if (format & DW_EH_PE_pcrel)
  {
    value += [self fileOffsetToRVA:offset];
  }
  
  NSString * symbolName = [self findSymbolAtRVA:value];

  //NSLog(@"guessed at %X [%X]: %@", [self fileOffsetToRVA:offset], value, symbolName);
  
  return symbolName;
}

//-----------------------------------------------------------------------------
- (NSString *)guessSymbol64UsingEncoding:(uint8_t)format atOffset:(uint32_t)offset withValue:(uint64_t &)value
{
  NSParameterAssert([self is64bit] == YES);
  
  if (value == 0)
  {
    return @"0x0";
  }
  
  // extend external symbols represented in 32bit to 64bit
  if ((int32_t)value < 0)
  {
    value |= 0xffffffff00000000LL;
  }

  if (format & DW_EH_PE_pcrel)
  {
    value += [self fileOffsetToRVA64:offset];
  }
   
  NSString * symbolName = [self findSymbolAtRVA64:value];
  
  //NSLog(@"guessed at %qX [%qX]: %@", [self fileOffsetToRVA64:offset], value, symbolName);
  
  return symbolName;
}

//-----------------------------------------------------------------------------
// Call Frame Information
//-----------------------------------------------------------------------------
- (MVNode *)createCFINode:(MVNode *)parent
                caption:(NSString *)caption
               location:(uint32_t)location
                 length:(uint32_t)length
{
  MVNodeSaver nodeSaver;
  MVNode * node = [parent insertChildWithDetails:caption location:location length:length saver:nodeSaver]; 
  
  NSRange range = NSMakeRange(location,0);
  NSString * lastReadHex;
  
  /////////////////////////////////////////////////////////
  //            Common Information Entry
  
  uint8_t Pointer_encoding = DW_EH_PE_omit;
  uint8_t LSDA_encoding = DW_EH_PE_omit;
  
  //Length (Required)
  // A 4 byte unsigned value indicating the length in bytes of the CIE structure, not including the Length field itself. 
  // If Length contains the value 0xffffffff, then the length is contained in the Extended Length field. 
  // If Length contains the value 0, then this CIE shall be considered a terminator and processing shall end.
  uint32_t CIE_length = [dataController read_uint32:range lastReadHex:&lastReadHex];
  [node.details appendRow:[NSString stringWithFormat:@"%.8lX", range.location]
                         :lastReadHex
                         :@"CIE Length"
                         :[NSString stringWithFormat:@"%u", CIE_length]];
  
  //Extended Length (Optional)
  // A 8 byte unsigned value indicating the length in bytes of the CIE structure, not including the Length and Extended Length fields.
  NSAssert (CIE_length != 0xffffffff, @"CIE Extended length present");
  
  //CIE ID (Required)
  // A 4 byte unsigned value that is used to distinguish CIE records from FDE records. 
  // This value shall always be 0, which indicates this record is a CIE.
  uint32_t CIE_ID = [dataController read_uint32:range lastReadHex:&lastReadHex]; CIE_length -= range.length;
  [node.details appendRow:[NSString stringWithFormat:@"%.8lX", range.location]
                         :lastReadHex
                         :@"CIE ID"
                         :[NSString stringWithFormat:@"%u", CIE_ID]];
  
  //Version (Required)
  // Version assigned to the call frame information structure. This value shall be 1.
  uint8_t CIE_version = [dataController read_uint8:range lastReadHex:&lastReadHex]; CIE_length -= range.length;
  [node.details appendRow:[NSString stringWithFormat:@"%.8lX", range.location]
                         :lastReadHex
                         :@"CIE Version"
                         :[NSString stringWithFormat:@"%u", CIE_version]];
  
  //Augmentation String (Required)
  // This value is a NUL terminated string that identifies the augmentation to the CIE or to the FDEs associated with this CIE. 
  // A zero length string indicates that no augmentation data is present. 
  NSString * CIE_augmentationStr = [dataController read_string:range lastReadHex:&lastReadHex]; CIE_length -= range.length;
  [node.details appendRow:[NSString stringWithFormat:@"%.8lX", range.location]
                         :lastReadHex
                         :@"Augmentation String"
                         :CIE_augmentationStr];
  
  //EH Data present (Optional)
  // On 32 bit architectures, this is a 4 byte value that... On 64 bit architectures, this is a 8 byte value that... 
  NSAssert ([CIE_augmentationStr rangeOfString:@"eh"].location == NSNotFound, @"EH Data field is present");
  
  //Code Alignment Factor (Required)
  // An unsigned LEB128 encoded value that is factored out of all advance location instructions that are associated with this CIE or its FDEs.
  // This value shall be multiplied by the delta argument of an adavance location instruction to obtain the new location value.
  uint64_t CIE_codeAlignFactor = [dataController read_uleb128:range lastReadHex:&lastReadHex]; CIE_length -= range.length;
  [node.details appendRow:[NSString stringWithFormat:@"%.8lX", range.location]
                         :lastReadHex
                         :@"Code Alignment Factor"
                         :[NSString stringWithFormat:@"%qu", CIE_codeAlignFactor]];
  
  //Data Alignment Factor (Required)
  // A signed LEB128 encoded value that is factored out of all offset instructions that are associated with this CIE or its FDEs. 
  // This value shall be multiplied by the register offset argument of an offset instruction to obtain the new offset value.
  int64_t CIE_dataAlignFactor = [dataController read_sleb128:range lastReadHex:&lastReadHex]; CIE_length -= range.length;
  [node.details appendRow:[NSString stringWithFormat:@"%.8lX", range.location]
                         :lastReadHex
                         :@"Data Alignment Factor"
                         :[NSString stringWithFormat:@"%qd", CIE_dataAlignFactor]];
  
  //Return Address Register	(Required)
  uint8_t CIE_returnAddressRegister = [dataController read_uint8:range lastReadHex:&lastReadHex]; CIE_length -= range.length;
  [node.details appendRow:[NSString stringWithFormat:@"%.8lX", range.location]
                         :lastReadHex
                         :@"Return Address Register"
                         :[NSString stringWithFormat:@"0x%X", CIE_returnAddressRegister]];
  
  // A 'z' may be present as the first character of the string. If present, the Augmentation Data field shall be present. 
  // The contents of the Augmentation Data shall be intepreted according to other characters in the Augmentation String.
  if ([CIE_augmentationStr rangeOfString:@"z"].location != NSNotFound)
  {
    //Augmentation Data Length (Optional)
    // An unsigned LEB128 encoded value indicating the length in bytes of the Augmentation Data. 
    // This field is only present if the Augmentation String contains the character 'z'.
    uint64_t CIE_augmentationLength = [dataController read_uleb128:range lastReadHex:&lastReadHex]; CIE_length -= range.length;
    [node.details appendRow:[NSString stringWithFormat:@"%.8lX", range.location]
                           :lastReadHex
                           :@"Augmentation Length"
                           :[NSString stringWithFormat:@"%qu", CIE_augmentationLength]];
    
    //Augmentation Data	(Optional)
    // A block of data whose contents are defined by the contents of the Augmentation String as described below. 
    // This field is only present if the Augmentation String contains the character 'z'.
    for (NSUInteger strIndex = 1; strIndex < [CIE_augmentationStr length]; ++strIndex)
    {
      switch ([CIE_augmentationStr characterAtIndex:strIndex])
      {
        case 'L':
          // A 'L' may be present at any position after the first character of the string. 
          // This character may only be present if 'z' is the first character of the string. 
          // If present, it indicates the presence of one argument in the Augmentation Data of the CIE, and a corresponding argument in the Augmentation Data of the FDE. 
          // The argument in the Augmentation Data of the CIE is 1-byte and represents the pointer encoding used for the argument in the Augmentation Data of the FDE, which is the address of a language-specific data area (LSDA). 
          // The size of the LSDA pointer is specified by the pointer encoding used.
        {
          LSDA_encoding = [dataController read_uint8:range lastReadHex:&lastReadHex];
          [node.details appendRow:[NSString stringWithFormat:@"%.8lX", range.location]
                                 :lastReadHex
                                 :@"LSDA Encoding in FDE"
                                 :[self getNameForEncoding:LSDA_encoding]];
        } break;
      
        case 'P':
          // A 'P' may be present at any position after the first character of the string. 
          // This character may only be present if 'z' is the first character of the string.
          // If present, it indicates the presence of two arguments in the Augmentation Data of the CIE. 
          // The first argument is 1-byte and represents the pointer encoding used for the second argument, which is the address of a personality routine handler. 
          // The size of the personality routine pointer is specified by the pointer encoding used.
        {
          // personality routine encoding
          uint8_t PR_encoding = [dataController read_uint8:range lastReadHex:&lastReadHex];
          [node.details appendRow:[NSString stringWithFormat:@"%.8lX", range.location]
                                 :lastReadHex
                                 :@"Personality Encoding"
                                 :[self getNameForEncoding:PR_encoding]];
          
          uint64_t PR_offset = READ_USE_ENCODING(PR_encoding,range,lastReadHex);
          [node.details appendRow:[NSString stringWithFormat:@"%.8lX", range.location]
                                 :lastReadHex
                                 :@"Personality Routine"
                                 :[self is64bit] == NO
                                    ? [self guessSymbolUsingEncoding:PR_encoding atOffset:range.location withValue:(uint32_t &)PR_offset]
                                    : [self guessSymbol64UsingEncoding:PR_encoding atOffset:range.location withValue:PR_offset]];
        } break;
      
        case 'R':
          // A 'R' may be present at any position after the first character of the string. 
          // This character may only be present if 'z' is the first character of the string. 
          // If present, The Augmentation Data shall include a 1 byte argument that represents the pointer encoding for the address pointers used in the FDE.
        {
          Pointer_encoding = [dataController read_uint8:range lastReadHex:&lastReadHex];
          [node.details appendRow:[NSString stringWithFormat:@"%.8lX", range.location]
                                 :lastReadHex
                                 :@"Pointer Encoding in FDE"
                                 :[self getNameForEncoding:Pointer_encoding]];
        } break;
          
      } // switch
    } // loop
    
    CIE_length -= CIE_augmentationLength;
    
  } // read augmentation data
  
  //Initial Instructions (Required)
  // Initial set of Call Frame Instructions.
  [dataController read_bytes:range length:CIE_length lastReadHex:&lastReadHex];
  [node.details appendRow:[NSString stringWithFormat:@"%.8lX", range.location]
                         :lastReadHex
                         :@"Initial Instructions"
                         :@""];

  [node.details setAttributes:MVUnderlineAttributeName,@"YES",nil];
  
  /////////////////////////////////////////////////////////
  //        Frame Description Entry (FDE) Records
  
  if (Pointer_encoding != DW_EH_PE_omit)
  while (NSMaxRange(range) - location < length)
  {
    // accumulate search info
    NSUInteger bookmark = node.details.rowCount;
    NSString * symbolName = nil;
    
    //Length	(Required)
    // A 4 byte unsigned value indicating the length in bytes of the CIE structure, not including the Length field itself. 
    // If Length contains the value 0xffffffff, then the length is contained the Extended Length field. 
    // If Length contains the value 0, then this CIE shall be considered a terminator and processing shall end.
    uint32_t FDE_length = [dataController read_uint32:range lastReadHex:&lastReadHex];
    [node.details appendRow:[NSString stringWithFormat:@"%.8lX", range.location]
                           :lastReadHex
                           :@"FDE Length"
                           :[NSString stringWithFormat:@"%u", FDE_length]];
    
    //Extended Length	(Optional)
    // A 8 byte unsigned value indicating the length in bytes of the CIE structure, not including the Length field itself.
    NSAssert (FDE_length != 0xffffffff, @"FDE Extended length present");
    
    //CIE Pointer	(Required)
    // A 4 byte unsigned value that when subtracted from the offset of the current FDE yields the offset of the start of the associated CIE. 
    // This value shall never be 0.
    uint32_t FDE_CIEvalue = [dataController read_uint32:range lastReadHex:&lastReadHex]; FDE_length -= range.length;
    
    // we ran out of FDE records and started to process the forthcoming CIE !! 
    // rollback until the begining of the CIE
    if (FDE_CIEvalue == 0)
    {
      [node.details popRow];
      break;
    }
    
    uint64_t FDE_CIEpointer = ([self is64bit] == NO 
                                ? [self fileOffsetToRVA:range.location] 
                                : [self fileOffsetToRVA64:range.location]) - FDE_CIEvalue;

    [node.details appendRow:[NSString stringWithFormat:@"%.8lX", range.location]
                           :lastReadHex
                           :@"CIE Pointer"
                           :[self is64bit] == NO
                              ? [self findSymbolAtRVA:(uint32_t)FDE_CIEpointer]
                              : [self findSymbolAtRVA64:FDE_CIEpointer]];
    
    //PC Begin	(Required)
    // An encoded constant that indicates the address of the initial location associated with this FDE.
    uint64_t PCBegin_addr = READ_USE_ENCODING(Pointer_encoding,range,lastReadHex); FDE_length -= range.length;
    [node.details appendRow:[NSString stringWithFormat:@"%.8lX", range.location]
                           :lastReadHex
                           :@"PC Begin"
                           :[self is64bit] == NO
                              ? (symbolName = [self guessSymbolUsingEncoding:Pointer_encoding atOffset:range.location withValue:(uint32_t &)PCBegin_addr])
                              : (symbolName = [self guessSymbol64UsingEncoding:Pointer_encoding atOffset:range.location withValue:PCBegin_addr])];

    //PC Range	(Required)
    // An encoded constant that indicates the number of bytes of instructions associated with this FDE.
    uint64_t FDE_PCRange = READ_USE_ENCODING(Pointer_encoding,range,lastReadHex); FDE_length -= range.length;
    [node.details appendRow:[NSString stringWithFormat:@"%.8lX", range.location]
                           :lastReadHex
                           :@"PC Range"
                           :[NSString stringWithFormat:@"%qu", FDE_PCRange]];
    
    if ([CIE_augmentationStr rangeOfString:@"z"].location != NSNotFound)
    {
      //Augmentation Data Length	(Optional)
      // An unsigned LEB128 encoded value indicating the length in bytes of the Augmentation Data. 
      // This field is only present if the Augmentation String in the associated CIE contains the character 'z'.
      uint64_t FDE_augmentationLength = [dataController read_uleb128:range lastReadHex:&lastReadHex]; FDE_length -= range.length;
      [node.details appendRow:[NSString stringWithFormat:@"%.8lX", range.location]
                             :lastReadHex
                             :@"Augmentation Length"
                             :[NSString stringWithFormat:@"%qu", FDE_augmentationLength]];
      
      if (FDE_augmentationLength > 0) // LSDA is present
      {
        //Augmentation Data	(Optional)
        // A block of data whose contents are defined by the contents of the Augmentation String in the associated CIE as described above. 
        // This field is only present if the Augmentation String in the associated CIE contains the character 'z'.
        uint64_t LSDA_addr = READ_USE_ENCODING(LSDA_encoding,range,lastReadHex); FDE_length -= range.length;
        [node.details appendRow:[NSString stringWithFormat:@"%.8lX", range.location]
                               :lastReadHex
                               :@"LSDA"
                               :[self is64bit] == NO 
                                  ? [self guessSymbolUsingEncoding:LSDA_encoding atOffset:range.location withValue:(uint32_t &)LSDA_addr]
                                  : [self guessSymbol64UsingEncoding:LSDA_encoding atOffset:range.location withValue:LSDA_addr]];
        
        if (LSDA_addr != 0)
        {
          lsdaInfo[LSDA_addr] = PCBegin_addr;
        }
      }
    }
    
    //Call Frame Instructions	(Required)
    // A set of Call Frame Instructions.
    [dataController read_bytes:range length:FDE_length lastReadHex:&lastReadHex];
    [node.details appendRow:[NSString stringWithFormat:@"%.8lX", range.location]
                           :lastReadHex
                           :@"Call Frame Instructions"
                           :@""];
    
    [node.details setAttributesFromRowIndex:bookmark:MVMetaDataAttributeName,symbolName,nil];
    [node.details setAttributes:MVUnderlineAttributeName,@"YES",nil];

  }
  
  return node;
}

//-----------------------------------------------------------------------------
//                     Language Specific Data Area
//-----------------------------------------------------------------------------
/*  #header
 *  .byte       @LPStart format     (usually <omit>)
 *  .byte       @TType format       (usually <omit>, <absolute> or <indirect pcrel sdata4>) 
 *  .uleb128    @TType base offset  (optional depending on TType format)
 *  .byte       Call-site format
 *  .uleb128    Call-site table length
 *
 *  #call-site table
 *  .long       region 0 start
 *  .long       length
 *  .long       landing pad
 *    ...
 *
 *  #Action record table
 *  .sleb128    typeFilter 1
 *  .sleb128    nextAction
 *  .sleb128    typeFilter 2
 *  .sleb128    nextAction
 *    ...
 *
 *  #Types table
 *  .align 2
 *  .long       typeInfo 3
 *  .long       typeInfo 2
 *  .long       typeInfo 1
 * ------------------------------- TTableBase
 *  .sleb128    typeIndex 1
 *  .sleb128    typeIndex 2
 *  .sleb128    0
 *  .sleb128    typeIndex 3
 *  .sleb128    0
 */
//===========================================================

- (MVNode *)createLSDANode:(MVNode *)parent
                 caption:(NSString *)caption
                location:(uint32_t)location
                  length:(uint32_t)length
          eh_frame_begin:(uint64_t)eh_frame_begin
              
{
  MVNodeSaver nodeSaver;
  MVNode * node = [parent insertChildWithDetails:caption location:location length:length saver:nodeSaver]; 
  
  NSRange range = NSMakeRange(location,0);
  NSString * lastReadHex;
  
  //===================== LSDA Header =======================
  uint8_t LPStartFormat = [dataController read_uint8:range lastReadHex:&lastReadHex];
  [node.details appendRow:[NSString stringWithFormat:@"%.8lX", range.location]
                         :lastReadHex
                         :@"@LPStart format"
                         :[self getNameForEncoding:LPStartFormat]];
  
  uint8_t typeTableFormat = [dataController read_uint8:range lastReadHex:&lastReadHex];
  [node.details appendRow:[NSString stringWithFormat:@"%.8lX", range.location]
                         :lastReadHex
                         :@"@TType format"
                         :[self getNameForEncoding:typeTableFormat]];
  
  uint32_t typeTableBaseLocation = 0;
  if (typeTableFormat != DW_EH_PE_omit)
  {
    uint64_t typeTableBaseOffset = [dataController read_uleb128:range lastReadHex:&lastReadHex];
    typeTableBaseLocation = NSMaxRange(range) + typeTableBaseOffset;
    [node.details appendRow:[NSString stringWithFormat:@"%.8lX", range.location]
                           :lastReadHex
                           :@"Type Table Base"
                           :[self is64bit] == NO ? [NSString stringWithFormat:@"0x%X",[self fileOffsetToRVA:typeTableBaseLocation]] : 
                                                   [NSString stringWithFormat:@"0x%qX",[self fileOffsetToRVA64:typeTableBaseLocation]]];
  }
    
  uint8_t callSiteFormat = [dataController read_uint8:range lastReadHex:&lastReadHex];
  [node.details appendRow:[NSString stringWithFormat:@"%.8lX", range.location]
                         :lastReadHex
                         :@"call-site format"
                         :[self getNameForEncoding:callSiteFormat]];
  
  uint64_t callSiteTableLength = [dataController read_uleb128:range lastReadHex:&lastReadHex];
  [node.details appendRow:[NSString stringWithFormat:@"%.8lX", range.location]
                         :lastReadHex
                         :@"call-site table length"
                         :[NSString stringWithFormat:@"%qu", callSiteTableLength]];
 
  [node.details setAttributes:MVUnderlineAttributeName,@"YES",nil];
  
  //==================== Call Sites Table ====================
  NSAssert (callSiteFormat == DW_EH_PE_udata4, @"Not yet implemeted encoding for call-site format");

  set<uint64_t> actions;

  do 
  {
    uint64_t regionStart = READ_USE_ENCODING(callSiteFormat,range,lastReadHex);
    [node.details appendRow:[NSString stringWithFormat:@"%.8lX", range.location]
                           :lastReadHex
                           :@"region start"
                           :[NSString stringWithFormat:@"0x%qX", eh_frame_begin + regionStart]];
    
    uint64_t regionLength = READ_USE_ENCODING(callSiteFormat,range,lastReadHex);
    [node.details appendRow:[NSString stringWithFormat:@"%.8lX", range.location]
                           :lastReadHex
                           :@"length"
                           :[NSString stringWithFormat:@"%qu", regionLength]];
    
    uint64_t landingPad = READ_USE_ENCODING(callSiteFormat,range,lastReadHex);
    [node.details appendRow:[NSString stringWithFormat:@"%.8lX", range.location]
                           :lastReadHex
                           :@"landing pad"
                           :landingPad == 0 ? @"0x0" : [NSString stringWithFormat:@"0x%qX", eh_frame_begin + landingPad]];
    
    uint64_t action = [dataController read_uleb128:range lastReadHex:&lastReadHex];
    [node.details appendRow:[NSString stringWithFormat:@"%.8lX", range.location]
                           :lastReadHex
                           :@"action"
                           :[NSString stringWithFormat:@"%qu", action]];
   
    if (action > 0)
    {
      actions.insert(action);
    }
    
    [node.details setAttributes:MVUnderlineAttributeName,@"YES",nil];

  } while (NSMaxRange(range) - location < callSiteTableLength);
  
  //================== Action record table ================
  if (typeTableFormat != DW_EH_PE_omit)
  {
    typedef set<int32_t> IndexSet;
    IndexSet typeIndexes;
    IndexSet exceptionSpecs;

    // traverse the action table and collect type table records
    int64_t currentAction = 1;    
    while (actions.empty() == false)
    {
      actions.erase (currentAction);
      
      int64_t index = [dataController read_sleb128:range lastReadHex:&lastReadHex]; currentAction += range.length;
      [node.details appendRow:[NSString stringWithFormat:@"%.8lX", range.location]
                             :lastReadHex
                             :@"Type Filter"
                             :[NSString stringWithFormat:@"%qd", index]];
      
      if (index > 0)
      {
        typeIndexes.insert(index);
      }
      else if (index < 0)
      {
        exceptionSpecs.insert(index);
      }
    
      int64_t nextAction = [dataController read_sleb128:range lastReadHex:&lastReadHex]; currentAction += range.length;
      [node.details appendRow:[NSString stringWithFormat:@"%.8lX", range.location]
                             :lastReadHex
                             :@"Next Action"
                             :[NSString stringWithFormat:@"%qd", nextAction]];
      
      if (nextAction >= currentAction)
      {
        actions.insert (nextAction);
      }
    } 

    [node.details setAttributes:MVUnderlineAttributeName,@"YES",nil];
    
    
    //================== Types table ================
    
    // collect additional type indexes from exception specifications
    for (IndexSet::iterator iter = exceptionSpecs.begin(); iter != exceptionSpecs.end(); ++iter)
    {
      int32_t index = *iter;

      NSRange range = NSMakeRange(typeTableBaseLocation - index - 1, 0);
      
      // Negative value, starting at -1, which is the byte offset in the types table of a null-terminated list of type indexes. 
      // The list will be at TTBase+1 for -1, at TTBase+2 for -2, and so on.
      // Used by the runtime to match the type of the thrown exception with the types specified in the “throw” list.
      // note: they are SLEB128 entries
      for (;;)
      {
        index = [dataController read_sleb128:range lastReadHex:&lastReadHex];
        if (index == 0)
        {
          break;
        }
        typeIndexes.insert(index);
      }
    }
    
    // traverse type filters in reverse order (starting with the catch clauses)
    for (IndexSet::reverse_iterator iter = typeIndexes.rbegin(); iter != typeIndexes.rend(); ++iter)
    {
      int32_t index = *iter;
      NSParameterAssert (index > 0);
      
      // Positive value, starting at 1. Index in the types table of the __typeinfo for the catch-clause type. 
      // 1 is the first word preceding TTBase, 2 is the second word, and so on. 
      // Used by the runtime to check if the thrown exception type matches the catch-clause type.
        
      uint32_t size = ENCODING_FIXSIZE(typeTableFormat);
      range = NSMakeRange(typeTableBaseLocation - index * size,0);
        
      uint64_t typeInfo = READ_USE_ENCODING(typeTableFormat,range,lastReadHex);
      [node.details appendRow:[NSString stringWithFormat:@"%.8lX", range.location]
                              :lastReadHex
                              :@"Type Info"
                              :[self is64bit] == NO
                                ? [self guessSymbolUsingEncoding:typeTableFormat atOffset:range.location withValue:(uint32_t &)typeInfo]
                                : [self guessSymbol64UsingEncoding:typeTableFormat atOffset:range.location withValue:typeInfo]];
    }
    
    [node.details setAttributes:MVUnderlineAttributeName,@"YES",nil];
    
    // Exception Specifications
    range = NSMakeRange (typeTableBaseLocation, 0);
    while (NSMaxRange(range) < location + length)
    {
      int64_t index = [dataController read_sleb128:range lastReadHex:&lastReadHex];
      [node.details appendRow:[NSString stringWithFormat:@"%.8lX", range.location]
                             :lastReadHex
                             :@"Exception Spec"
                             :[NSString stringWithFormat:@"%lld", index]];
    }
    
  } // end of Action Record Table

  return node;
}

//-----------------------------------------------------------------------------
//    !!!!!! DISCONTINUED !!!!! (not mandatory, can be ommited)
//-----------------------------------------------------------------------------
- (MVNode *)createUnwindInfoHeaderNode:(MVNode *)parent
                               caption:(NSString *)caption
                              location:(uint32_t)location
                                header:(struct unwind_info_section_header const *)unwind_info_section_header
{
  MVNodeSaver nodeSaver;
  MVNode * node = [parent insertChildWithDetails:caption location:location length:sizeof(struct unwind_info_section_header) saver:nodeSaver]; 
  
  NSRange range = NSMakeRange(location,0);
  NSString * lastReadHex;

  uint32_t version = [dataController read_uint32:range lastReadHex:&lastReadHex];
  [node.details appendRow:[NSString stringWithFormat:@"%.8lX", range.location]
                         :lastReadHex
                         :@"Unwind Section Version"
                         :version == UNWIND_SECTION_VERSION ? @"UNWIND_SECTION_VERSION" : [NSString stringWithFormat:@"%u", version]];
  
  NSAssert1(version == UNWIND_SECTION_VERSION, @"unsupported unwind section version (%u)", version);
  
  uint32_t commonEncodingsArraySectionOffset = [dataController read_uint32:range lastReadHex:&lastReadHex];
  [node.details appendRow:[NSString stringWithFormat:@"%.8lX", range.location]
                         :lastReadHex
                         :@"Common Enc Array Sect Offset"
                         :[self is64bit] == NO 
                            ? [self findSymbolAtRVA:[self fileOffsetToRVA:range.location] + commonEncodingsArraySectionOffset]
                            : [self findSymbolAtRVA64:[self fileOffsetToRVA64:range.location] + commonEncodingsArraySectionOffset]];
  
  uint32_t commonEncodingsArrayCount = [dataController read_uint32:range lastReadHex:&lastReadHex];
  [node.details appendRow:[NSString stringWithFormat:@"%.8lX", range.location]
                         :lastReadHex
                         :@"Common Enc Array Count"
                         :[NSString stringWithFormat:@"%u", commonEncodingsArrayCount]];

  uint32_t personalityArraySectionOffset = [dataController read_uint32:range lastReadHex:&lastReadHex];
  [node.details appendRow:[NSString stringWithFormat:@"%.8lX", range.location]
                         :lastReadHex
                         :@"Personality Array Sect Offset"
                         :[self is64bit] == NO 
                            ? [self findSymbolAtRVA:[self fileOffsetToRVA:range.location] + personalityArraySectionOffset]
                            : [self findSymbolAtRVA64:[self fileOffsetToRVA64:range.location] + personalityArraySectionOffset]];

  uint32_t personalityArrayCount = [dataController read_uint32:range lastReadHex:&lastReadHex];
  [node.details appendRow:[NSString stringWithFormat:@"%.8lX", range.location]
                         :lastReadHex
                         :@"Personality Array Count"
                         :[NSString stringWithFormat:@"%u", personalityArrayCount]];

  uint32_t indexSectionOffset = [dataController read_uint32:range lastReadHex:&lastReadHex];
  [node.details appendRow:[NSString stringWithFormat:@"%.8lX", range.location]
                         :lastReadHex
                         :@"Index Section Offset"
                         :[self is64bit] == NO 
                            ? [self findSymbolAtRVA:[self fileOffsetToRVA:range.location] + indexSectionOffset]
                            : [self findSymbolAtRVA64:[self fileOffsetToRVA64:range.location] + indexSectionOffset]];  

  uint32_t indexCount = [dataController read_uint32:range lastReadHex:&lastReadHex];
  [node.details appendRow:[NSString stringWithFormat:@"%.8lX", range.location]
                         :lastReadHex
                         :@"Index Count"
                         :[NSString stringWithFormat:@"%u", indexCount]];
  
  return node;
}
  
@end
