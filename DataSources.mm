/*
 *  DataSources.mm
 *  MachOView
 *
 *  Created by psaghelyi on 15/06/2010.
 *
 */

#import "Common.h"
#import "DataSources.h"
#import "DataController.h"
#import "Document.h"

NSString * const MVScannerErrorMessage  = @"NSScanner error";

//============================================================================
@implementation MVDataSourceTree

#pragma mark NSOutlineView must-have delegates

- (NSInteger)outlineView:(NSOutlineView *)outlineView numberOfChildrenOfItem:(id)item 
{
  if (item == nil)
  {
    return 1;
  }
  
  MVNode * node = item;
  return node.numberOfChildren;
}
//----------------------------------------------------------------------------

- (BOOL)outlineView:(NSOutlineView *)outlineView isItemExpandable:(id)item 
{
  if (item == nil)
  {
    return YES;
  }
  
  MVNode * node = item;
  return (node.numberOfChildren > 0);
}
//----------------------------------------------------------------------------

- (id)outlineView:(NSOutlineView *)outlineView child:(NSInteger)index ofItem:(id)item 
{
  MVDocument * document = [[[outlineView window] windowController] document];
  if (item == nil)
  {
    return document.dataController.rootNode;
  }
  
  MVNode * node = item;
  return [node childAtIndex:index];
}
//----------------------------------------------------------------------------

- (id)outlineView:(NSOutlineView *)outlineView objectValueForTableColumn:(NSTableColumn *)tableColumn byItem:(id)item 
{
  if (item == nil)
  {
    return @"-";
  }
  
  MVNode * node = item;
  
  if (node.details != nil && node.detailsOffset == 0)
  {
    return [@"*" stringByAppendingString:node.caption];
  }
  
  return node.caption;
}
//----------------------------------------------------------------------------

@end


//============================================================================
@implementation MVDataSourceDetails

#pragma mark NSTableView must-have delegates

- (NSInteger)numberOfBinaryRows:(MVNode *)node {
  NSInteger numRows = node.dataRange.length / 16;
  if (node.dataRange.length % 16 != 0)
  {
    ++numRows;
  }
  return numRows;
}

- (NSInteger)numberOfRowsInTableView:(NSTableView *)aTableView
{
  MVDocument * document = [[[aTableView window] windowController] document];
  MVNode * selectedNode = document.dataController.selectedNode;
  
  // if there is no details, then provide binary dump
  if (selectedNode.details == nil)
  {
    return [self numberOfBinaryRows:selectedNode];
  }
  return selectedNode.details.rowCountToDisplay;
}

//----------------------------------------------------------------------------

- (id)tableView:(NSTableView *)aTableView objectValueForTableColumn:(NSTableColumn *)aTableColumn row:(NSInteger)rowIndex
{
  MVDocument * document = [[[aTableView window] windowController] document];
  MVNode * selectedNode = document.dataController.selectedNode;
  
  // if it is closing...
  if (document == nil)
  {
    return nil;
  }
  
  NSUInteger colIndex = [[aTableView tableColumns] indexOfObject:aTableColumn];
  
  //NSLog (@"queried (%d, %d)", rowIndex, colIndex);
  
  // if it has no details then show binary data at given range
  if (selectedNode.details == nil)
  {
    return [self getBinaryString:rowIndex column:colIndex doc:document];
  }
  
  // if it has descripion then show it
  return [self getDetailString:rowIndex column:colIndex doc:document];
}
//----------------------------------------------------------------------------

- (void)tableView:(NSTableView *)aTableView setObjectValue:(id)anObject forTableColumn:(NSTableColumn *)aTableColumn row:(NSInteger)rowIndex
{
  BOOL scanResult;
  uint32_t fileOffset;

  NSUInteger colIndex = [[aTableView tableColumns] indexOfObject:aTableColumn];
  MVDocument * document = [[[aTableView window] windowController] document];
  NSString * cellContent = ([anObject isKindOfClass:[NSAttributedString class]] ? [anObject string] : anObject);
  NSScanner * scanner = [NSScanner scannerWithString:cellContent];
  MVNode * selectedNode = document.dataController.selectedNode;
  
  if (selectedNode.details != nil)
  // option1: plain hex value
  {
    MVRow * row = [selectedNode.details getRowToDisplay:rowIndex];
    if (row == nil)
    {
      return;
    }
    
    // find out file offset from the offset column
    scanResult = [[NSScanner scannerWithString:row.coloumns.offsetStr]
                                    scanHexInt:&fileOffset];
    if (scanResult == NO)
    {
      NSAssert(NO, MVScannerErrorMessage);
      return;
    }
    
    NSRange dataRange = NSMakeRange(fileOffset, [cellContent length] / 2);
    
    if (dataRange.length <= sizeof(uint64_t))
    {
      uint64_t value;
      scanResult = [scanner scanHexLongLong:&value];
      if (scanResult == NO)
      {
        NSAssert(NO, MVScannerErrorMessage);
        return;
      }
      [document.dataController.fileData replaceBytesInRange:dataRange withBytes:&value];
    }
    else 
    {
      // create a place holder for new value
      NSAssert ([cellContent length] % 2 == 0, @"cell content length must be even");
      
      NSMutableData * mdata = [NSMutableData dataWithCapacity:dataRange.length];
      
      static char buf[3];
      char const * orgstr = CSTRING(cellContent);
      for (NSUInteger s = 0; s < [cellContent length]; s += 2)
      {
        buf[0] = orgstr[s];
        buf[1] = orgstr[s+1];
        unsigned value = strtoul (buf, NULL, 16);
        [mdata appendBytes:&value length:sizeof(uint8_t)];
      }
      
      // replace data with the new value
      [document.dataController.fileData replaceBytesInRange:dataRange withBytes:[mdata bytes]];
    }

    // update the cell content to indicate changes
    //================================================
    selectedNode.detailsOffset = 0;
    [selectedNode.details updateCellContentTo:cellContent atRow:rowIndex andCol:colIndex];
    [selectedNode.details setAttributesForRowIndex:rowIndex:MVTextColorAttributeName,[NSColor redColor],nil];
  }
  else
  // option2: group of bytes
  {
    // find out file offset from the row index
    fileOffset = selectedNode.dataRange.location + 16 * rowIndex + 8 * (colIndex == DATA_HI_COLUMN);

    // create a place holder for new value
    NSMutableData * mdata = [NSMutableData dataWithCapacity:[cellContent length] / 3]; // each element = one byte plus space
    
    // fill in placeholder
    while ([scanner isAtEnd] == NO)
    {
      unsigned value;
      
      scanResult = [scanner scanHexInt:&value];
      if (scanResult == NO)
      {
        NSAssert(NO, MVScannerErrorMessage);
        return;
      }
      
      [mdata appendBytes:&value length:sizeof(uint8_t)];
    }
    
    // replace data with the new value
    [document.dataController.fileData replaceBytesInRange:NSMakeRange(fileOffset, [mdata length]) 
                                                withBytes:[mdata bytes]];
    
    // do not need to update cell content...
  }

  // set document to dirty
  [document updateChangeCount:NSChangeDone];
}
//----------------------------------------------------------------------------

#pragma mark Utils

- (NSString *)getBinaryString:(NSInteger)rowIndex column:(NSInteger)colIndex doc:(MVDocument *)document {
  MVNode * selectedNode = document.dataController.selectedNode;
  NSUInteger offset = selectedNode.dataRange.location + rowIndex * 16;
  
  // file offset
  if (colIndex == OFFSET_COLUMN)
  {
    NSString * cellContent = [NSString stringWithFormat:@"%.8lX", offset];
    if ([document isRVA] == YES)
    {
      id layout = [selectedNode.userInfo objectForKey:MVLayoutUserInfoKey];
      return [layout performSelector:@selector(convertToRVA:) withObject:cellContent];
    }
    return cellContent;
  }

  // binary data
  uint8_t buffer[17] = {0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0};
  
  NSUInteger len = MIN(selectedNode.dataRange.length - rowIndex * 16, (NSUInteger)16);
  
  memcpy(buffer, (uint8_t *)[document.dataController.fileData bytes] + offset, len);
  
  if (colIndex == DATA_LO_COLUMN)
  {
    NSUInteger index = (len > 8 ? 8 : len);
          
    return [[NSString stringWithFormat:@"%.2X %.2X %.2X %.2X %.2X %.2X %.2X %.2X ",
            buffer[0], buffer[1], buffer[2], buffer[3], buffer[4], buffer[5], buffer[6], buffer[7]]
            substringToIndex:index*3];
  }
  
  if (colIndex == DATA_HI_COLUMN)
  {
    NSUInteger index = (len > 8 ? len - 8 : 0);
    
    return [[NSString stringWithFormat:@"%.2X %.2X %.2X %.2X %.2X %.2X %.2X %.2X ",
            buffer[8], buffer[9], buffer[10], buffer[11], buffer[12], buffer[13], buffer[14], buffer[15]]
            substringToIndex:index*3];
  }
  
  // textual data (where possible)
  for (NSUInteger i = 0; i < len; ++i)
  {
    // keep the output in ASCII
    if (buffer[i] < 32 || buffer[i] > 126)
    {
      buffer[i] = '.';
    }
  }
  
  return NSSTRING(buffer);
}

- (id)getDetailString:(NSInteger)rowIndex column:(NSInteger)colIndex doc:(MVDocument *)document {
  MVNode * selectedNode = document.dataController.selectedNode;
  MVRow * row = [selectedNode.details getRowToDisplay:rowIndex];
  if (row != nil)
  {
    NSString * cellContent = [row coloumnAtIndex:colIndex];
      
    // special column is the offset column:
    // if RVA is selected then subtitute the content on the fly
    if (colIndex == OFFSET_COLUMN && [cellContent length] > 0)
    {
      if ([document isRVA] == YES)
      {
        id layout = [selectedNode.userInfo objectForKey:MVLayoutUserInfoKey];
        cellContent = [layout performSelector:@selector(convertToRVA:) withObject:cellContent];
      }
    }
      
    // put formatting on display text
    NSColor * color = [row.attributes objectForKey:MVTextColorAttributeName];
    if (color != nil)
    {
      NSDictionary * attributes = [NSDictionary dictionaryWithObject:color forKey:NSForegroundColorAttributeName];
      return [[NSAttributedString alloc] initWithString:cellContent
                                             attributes:attributes];
    }
    return cellContent;
  }
  return nil;
}

- (NSString *)fullBinaryData:(NSTableView *)tableView {
  MVDocument * document = [[[tableView window] windowController] document];
  MVNode * selectedNode = document.dataController.selectedNode;
  
  NSInteger numRow = [self numberOfBinaryRows:selectedNode];
  NSMutableString *result = [NSMutableString new];
  for (NSInteger i = 0; i<numRow; ++i) {
    [result appendString:
      [NSString stringWithFormat:@"%@ %@ %@ %@\n",
      [self getBinaryString:i column:OFFSET_COLUMN doc:document],
      [self getBinaryString:i column:DATA_LO_COLUMN doc:document],
      [self getBinaryString:i column:DATA_HI_COLUMN doc:document],
      [self getBinaryString:i column:VALUE_COLUMN doc:document]
      ]
    ];
  }
  return result;
}

- (NSString *)fullDetailData:(NSTableView *)tableView {
  MVDocument * document = [[[tableView window] windowController] document];
  MVNode * selectedNode = document.dataController.selectedNode;
  
  NSInteger numRow = selectedNode.details.rowCountToDisplay;
  NSMutableString *result = [NSMutableString new];
  for (NSInteger i = 0; i<numRow; ++i) {
    [result appendString:
      [NSString stringWithFormat:@"%@ %@ %@ %@\n",
      [self getDetailString:i column:OFFSET_COLUMN doc:document],
      [self getDetailString:i column:DATA_COLUMN doc:document],
      [self getDetailString:i column:DESCRIPTION_COLUMN doc:document],
      [self getDetailString:i column:VALUE_COLUMN doc:document]]
    ];
  }
  return result;
}

@end
