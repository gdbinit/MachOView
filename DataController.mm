/*
 *  DataController.mm
 *  MachOView
 *
 *  Created by psaghelyi on 15/06/2010.
 *
 */

#import "Common.h"
#import "DataController.h"
#import "MachOLayout.h"
#import "FatLayout.h"
#import "ArchiveLayout.h"

enum {
  MVUnderlineAttributeOrdinal = 1,
  MVCellColorAttributeOrdinal,
  MVTextColorAttributeOrdinal,
  MVMetaDataAttributeOrdinal
};

enum {
  MVBlackColorOrdinal = 1,
  MVDarkGrayColorOrdinal,
  MVLightGrayColorOrdinal,
  MVWhiteColorOrdinal,
  MVGrayColorOrdinal,
  MVRedColorOrdinal,
  MVGreenColorOrdinal,
  MVBlueColorOrdinal,
  MVCyanColorOrdinal,
  MVYellowColorOrdinal,
  MVMagentaColorOrdinal,
  MVOrangeColorOrdinal,
  MVPurpleColorOrdinal,
  MVBrownColorOrdinal
};

NSString * const MVUnderlineAttributeName         = @"MVUnderlineAttribute";
NSString * const MVCellColorAttributeName         = @"MVCellColorAttribute";
NSString * const MVTextColorAttributeName         = @"MVTextColorAttribute";
NSString * const MVMetaDataAttributeName          = @"MVMetaDataAttribute";

NSString * const MVLayoutUserInfoKey              = @"MVLayoutUserInfoKey";
NSString * const MVNodeUserInfoKey                = @"MVNodeUserInfoKey";
NSString * const MVStatusUserInfoKey              = @"MVStatusUserInfoKey";

NSString * const MVDataTreeWillChangeNotification = @"MVDataTreeWillChangeNotification";
NSString * const MVDataTreeDidChangeNotification  = @"MVDataTreeDidChangeNotification";
NSString * const MVDataTreeChangedNotification    = @"MVDataTreeChanged";
NSString * const MVDataTableChangedNotification   = @"MVDataTableChanged";
NSString * const MVThreadStateChangedNotification = @"MVThreadStateChanged";

NSString * const MVStatusTaskStarted              = @"MVStatusTaskStarted";
NSString * const MVStatusTaskTerminated           = @"MVStatusTaskTerminated";

//============================================================================
@implementation MVColoumns

@synthesize offsetStr, dataStr, descriptionStr, valueStr; 

//-----------------------------------------------------------------------------
- (id)init 
{
  self = [super init];
  if (self)
  {
#ifdef MV_STATISTICS
    OSAtomicIncrement64(&nrow_loaded);
#endif
  }
  return self;
}

//-----------------------------------------------------------------------------
-(id)initWithData:(NSString *)col0 :(NSString *)col1 :(NSString *)col2 :(NSString *)col3
{
  if (self = [super init])
  {
    offsetStr = col0;
    dataStr = col1;
    descriptionStr = col2;
    valueStr = col3;
    
#ifdef MV_STATISTICS
    OSAtomicIncrement64(&nrow_loaded);
#endif
  }
  return self;
}

//-----------------------------------------------------------------------------
+(MVColoumns *) coloumnsWithData:(NSString *)col0 :(NSString *)col1 :(NSString *)col2 :(NSString *)col3
{
  return [[MVColoumns alloc] initWithData:col0:col1:col2:col3];
}

//-----------------------------------------------------------------------------
-(void)dealloc
{
#ifdef MV_STATISTICS
  OSAtomicDecrement64(&nrow_loaded);
#endif
}

@end


//============================================================================
@implementation MVRow

@synthesize coloumns, attributes, offset, deleted, dirty;

//-----------------------------------------------------------------------------
- (id)init 
{
  self = [super init];
  if (self)
  {
#ifdef MV_STATISTICS
    OSAtomicIncrement64(&nrow_total);
#endif
  }
  return self;
}

//-----------------------------------------------------------------------------
-(void)dealloc
{
#ifdef MV_STATISTICS  
  OSAtomicDecrement64(&nrow_total);
#endif
}

//-----------------------------------------------------------------------------
-(NSString *)coloumnAtIndex:(NSUInteger)index
{
  switch (index)
  {
    case OFFSET_COLUMN:       return coloumns.offsetStr;
    case DATA_COLUMN:         return coloumns.dataStr;    
    case DESCRIPTION_COLUMN:  return coloumns.descriptionStr;
    case VALUE_COLUMN:        return coloumns.valueStr;
  }
  return nil;
}

//-----------------------------------------------------------------------------
-(void)replaceColoumnAtIndex:(NSUInteger)index withString:(NSString *)str
{
  coloumnsOffset = 0;
  
  
  switch (index)
  {
    case OFFSET_COLUMN:       coloumns.offsetStr = str; break;
    case DATA_COLUMN:         coloumns.dataStr = str;  break;
    case DESCRIPTION_COLUMN:  coloumns.descriptionStr = str; break;
    case VALUE_COLUMN:        coloumns.valueStr = str; break;
  }
}

//-----------------------------------------------------------------------------
- (void)writeString:(NSString *)str toFile:(FILE *)pFile
{
    if(str){
      fwrite(CSTRING(str), [str length] + 1, 1, pFile);
    }
}

//-----------------------------------------------------------------------------
- (NSString *)readStringFromFile:(FILE *)pFile
{
  std::string s;
  for(;;) 
  {
    char c = fgetc(pFile);
    if (!feof(pFile) && c)
      s += c;
    else
      break;
  }
  return NSSTRING(s.c_str()); 
}

//-----------------------------------------------------------------------------
- (void)writeColor:(NSColor *)color toFile:(FILE *)pFile
{
  int colorOrdinal = [color isEqualTo:[NSColor blackColor]]     ? MVBlackColorOrdinal
                   : [color isEqualTo:[NSColor darkGrayColor]]  ? MVDarkGrayColorOrdinal
                   : [color isEqualTo:[NSColor lightGrayColor]] ? MVLightGrayColorOrdinal
                   : [color isEqualTo:[NSColor whiteColor]]     ? MVWhiteColorOrdinal
                   : [color isEqualTo:[NSColor grayColor]]      ? MVGrayColorOrdinal
                   : [color isEqualTo:[NSColor redColor]]       ? MVRedColorOrdinal
                   : [color isEqualTo:[NSColor greenColor]]     ? MVGreenColorOrdinal
                   : [color isEqualTo:[NSColor blueColor]]      ? MVBlueColorOrdinal
                   : [color isEqualTo:[NSColor cyanColor]]      ? MVCyanColorOrdinal
                   : [color isEqualTo:[NSColor yellowColor]]    ? MVYellowColorOrdinal
                   : [color isEqualTo:[NSColor magentaColor]]   ? MVMagentaColorOrdinal
                   : [color isEqualTo:[NSColor orangeColor]]    ? MVOrangeColorOrdinal
                   : [color isEqualTo:[NSColor purpleColor]]    ? MVPurpleColorOrdinal
                   : [color isEqualTo:[NSColor brownColor]]     ? MVBrownColorOrdinal
                   : 0;
  
  putc(colorOrdinal, pFile);
  if (colorOrdinal == 0)
  {
  CGFloat red, green, blue, alpha;
  [color getRed:&red green:&green blue:&blue alpha:&alpha];
  float fred = red, fgreen = green, fblue = blue, falpha = alpha;
  fwrite(&fred, sizeof(float), 1, pFile);
  fwrite(&fgreen, sizeof(float), 1, pFile);
  fwrite(&fblue, sizeof(float), 1, pFile);
  fwrite(&falpha, sizeof(float), 1, pFile);
}
}

//-----------------------------------------------------------------------------
- (NSColor *)readColorFromFile:(FILE *)pFile
{
  int colorOrdinal = getc(pFile);
  switch (colorOrdinal)
  {
    case MVBlackColorOrdinal:     return [NSColor blackColor];
    case MVDarkGrayColorOrdinal:  return [NSColor darkGrayColor];
    case MVLightGrayColorOrdinal: return [NSColor lightGrayColor];
    case MVWhiteColorOrdinal:     return [NSColor whiteColor];
    case MVGrayColorOrdinal:      return [NSColor grayColor];
    case MVRedColorOrdinal:       return [NSColor redColor];
    case MVGreenColorOrdinal:     return [NSColor greenColor];
    case MVBlueColorOrdinal:      return [NSColor blueColor];
    case MVCyanColorOrdinal:      return [NSColor cyanColor];
    case MVYellowColorOrdinal:    return [NSColor yellowColor];
    case MVMagentaColorOrdinal:   return [NSColor magentaColor];
    case MVOrangeColorOrdinal:    return [NSColor orangeColor];
    case MVPurpleColorOrdinal:    return [NSColor purpleColor];
    case MVBrownColorOrdinal:     return [NSColor brownColor];
  }

  float fred, fgreen, fblue, falpha;
  fread(&fred, sizeof(float), 1, pFile);
  fread(&fgreen, sizeof(float), 1, pFile);
  fread(&fblue, sizeof(float), 1, pFile);
  fread(&falpha, sizeof(float), 1, pFile);
  return [NSColor colorWithDeviceRed:fred green:fgreen blue:fblue alpha:falpha];
}

//----------------------------------------------------------------------------
- (void)saveAttributestoFile:(FILE *)pFile
{
  uint32_t numAttributes = [attributes count];
  fwrite (&numAttributes, sizeof(uint32_t), 1, pFile);
  
  for (NSString * key in [attributes allKeys])
  {
    id value = [attributes objectForKey:key];
    if (value == nil)
    {
      continue;
    }
    
    int keyOrdinal = [key isEqualToString:MVUnderlineAttributeName] ? MVUnderlineAttributeOrdinal 
                   : [key isEqualToString:MVCellColorAttributeName] ? MVCellColorAttributeOrdinal
                   : [key isEqualToString:MVTextColorAttributeName] ? MVTextColorAttributeOrdinal
                   : [key isEqualToString:MVMetaDataAttributeName] ? MVMetaDataAttributeOrdinal
                   : 0;

    putc(keyOrdinal, pFile);
    switch (keyOrdinal)
    {
      case MVUnderlineAttributeOrdinal: [self writeString:value toFile:pFile]; break;
      case MVCellColorAttributeOrdinal: [self writeColor:value toFile:pFile]; break;
      case MVTextColorAttributeOrdinal: [self writeColor:value toFile:pFile]; break;
      case MVMetaDataAttributeOrdinal:  [self writeString:value toFile:pFile]; break;
      default: NSLog(@"warning: unknown attribute key");
    }
  }
}

//----------------------------------------------------------------------------
- (void)loadAttributesFromFile:(FILE *)pFile
{
  uint32_t numAttributes;
  fread (&numAttributes, sizeof(uint32_t), 1, pFile);
  
  NSMutableDictionary * _attributes = [[NSMutableDictionary alloc] initWithCapacity:numAttributes];
  while (numAttributes-- > 0)
  {
    int keyOrdinal = getc(pFile);
    switch (keyOrdinal)
    {
      case MVUnderlineAttributeOrdinal: [_attributes setObject:[self readStringFromFile:pFile] forKey:MVUnderlineAttributeName]; break;
      case MVCellColorAttributeOrdinal: [_attributes setObject:[self readColorFromFile:pFile] forKey:MVCellColorAttributeName]; break;
      case MVTextColorAttributeOrdinal: [_attributes setObject:[self readColorFromFile:pFile] forKey:MVTextColorAttributeName]; break;
      case MVMetaDataAttributeOrdinal:  [_attributes setObject:[self readStringFromFile:pFile] forKey:MVMetaDataAttributeName]; break;
      default: NSLog(@"warning: unknown attribute key");
    }
  }
  
  attributes = _attributes;
}

//----------------------------------------------------------------------------
- (void)saveToFile:(FILE *)pFile
{
  // dont need to seek, we always append new items
  //fseek(pFile, 0, SEEK_END);
  
  if (coloumnsOffset == 0) // isSaved == NO
  {
    uint32_t filePos = ftell(pFile);
    [self writeString:coloumns.offsetStr toFile:(FILE *)pFile];
    [self writeString:coloumns.dataStr toFile:(FILE *)pFile];
    [self writeString:coloumns.descriptionStr toFile:(FILE *)pFile];
    [self writeString:coloumns.valueStr toFile:(FILE *)pFile];
    coloumnsOffset = filePos;
  }
  
  if (dirty)
  {
    // reload the attributes if they are out of cache 
    if (attributesOffset > 0)
    {
      // import new items
      NSMutableDictionary * _attributes = [NSMutableDictionary dictionaryWithDictionary:attributes];
      
      // load old attributes
      fseek(pFile, attributesOffset, SEEK_SET);
      [self loadAttributesFromFile:pFile];
      fseek(pFile, 0, SEEK_END);
      
      // extend stored attributes with loaded items
      [_attributes addEntriesFromDictionary:attributes];
      
      // store extended attributes
      attributes = _attributes;
    }
    
    uint32_t filePos = ftell(pFile);
    [self saveAttributestoFile:(FILE *)pFile];
    dirty = NO;
    attributesOffset = filePos;
  }
}

//----------------------------------------------------------------------------
- (void)loadFromFile:(FILE *)pFile
{
  if (coloumns == nil)
  {
    NSParameterAssert(coloumnsOffset != 0);
    
    if (fseek(pFile, coloumnsOffset, SEEK_SET) == 0)
    {
      coloumns = [[MVColoumns alloc] init];
      
      coloumns.offsetStr = [self readStringFromFile:pFile];
      coloumns.dataStr = [self readStringFromFile:pFile];
      coloumns.descriptionStr = [self readStringFromFile:pFile];
      coloumns.valueStr = [self readStringFromFile:pFile];
    }
    else 
    {
      NSLog(@"*** reading error (coloumns) '%s'",strerror(errno));
      NSParameterAssert(0);
      return;
    }
  }
  
  if (attributes == nil && attributesOffset > 0)
  {
    if (fseek(pFile, attributesOffset, SEEK_SET) == 0)
    {
      [self loadAttributesFromFile:pFile];
    }
    else
    {
      NSLog(@"*** reading error (attributes) '%s'",strerror(errno));
      NSParameterAssert(0);
    }
  }
}

//----------------------------------------------------------------------------
- (void)saveIndexToFile:(FILE *)pFile
{
  fwrite(&offset, sizeof(uint32_t), 1, pFile);
  fwrite(&coloumnsOffset, sizeof(uint32_t), 1, pFile);
  fwrite(&attributesOffset, sizeof(uint32_t), 1, pFile);
  fwrite(&deleted, sizeof(BOOL), 1, pFile);
}

//----------------------------------------------------------------------------
- (void)loadIndexFromFile:(FILE *)pFile
{
  fread(&offset, sizeof(uint32_t), 1, pFile);
  fread(&coloumnsOffset, sizeof(uint32_t), 1, pFile);
  fread(&attributesOffset, sizeof(uint32_t), 1, pFile);
  fread(&deleted, sizeof(BOOL), 1, pFile);
}

//----------------------------------------------------------------------------
-(BOOL) isSaved
{
  return (coloumnsOffset > 0);
}

//----------------------------------------------------------------------------
-(void) clear
{
  if (coloumnsOffset > 0) // isSaved == YES
  {
    coloumns = nil;

    if (dirty == NO)
    {
      attributes = nil;
    }
  }
}

@end

//============================================================================
@implementation MVTable

@synthesize swapFile;

//-----------------------------------------------------------------------------
- (id)init
{
  NSAssert(NO, @"plain init is not allowed");
  return nil;
}

//-----------------------------------------------------------------------------
- (id)initWithArchiver:(MVArchiver *)_archiver
{
  if (self = [super init])
  {
    rows = [[NSMutableArray alloc] init];
    archiver = _archiver;
    tableLock = [[NSLock alloc] init];
  }
  return self;
}

//----------------------------------------------------------------------------
+(MVTable *) tableWithArchiver:(MVArchiver *)_archiver
{
  return [[MVTable alloc] initWithArchiver:_archiver];
}

//----------------------------------------------------------------------------
- (NSUInteger)rowCountToDisplay
{
  return [displayRows count];
}

//----------------------------------------------------------------------------
- (MVRow *)getRowToDisplay: (NSUInteger)rowIndex
{
  MVRow * row = nil;

  if (rowIndex < [displayRows count])
  {
    row = [displayRows objectAtIndex:rowIndex];
  }

  if (row != nil)
  {
    if (row.deleted)
    {
      row = nil;
    }
    else if (row.coloumns == nil)
    {
      [row loadFromFile:swapFile];
    }
  }

  return row;
}

//----------------------------------------------------------------------------
- (void)insertRowWithOffset:(uint32_t)offset :(id)col0 :(id)col1 :(id)col2 :(id)col3
{
  MVRow * row = [[MVRow alloc] init];
  row.coloumns = [MVColoumns coloumnsWithData:col0:col1:col2:col3];
  row.offset = offset;
  
  [tableLock lock];
  [rows addObject:row];
  [tableLock unlock];
  
  [archiver addObjectToSave:row];
}

//----------------------------------------------------------------------------
- (void)appendRow:(id)col0 :(id)col1 :(id)col2 :(id)col3
{
  [self insertRowWithOffset:0 :col0:col1:col2:col3];
}

//----------------------------------------------------------------------------
- (void)updateCellContentTo:(id)object atRow:(NSUInteger)rowIndex andCol:(NSUInteger)colIndex
{
  MVRow * row = [rows objectAtIndex:rowIndex];
  [row replaceColoumnAtIndex:colIndex withString:object];
  [rows replaceObjectAtIndex:rowIndex withObject:row];

  [archiver addObjectToSave:row];
}

//----------------------------------------------------------------------------
- (void)popRow
{
  MVRow * row = [rows lastObject];
  row.deleted = YES;
}

//----------------------------------------------------------------------------
- (NSUInteger)rowCount
{
  return [rows count];
}

//----------------------------------------------------------------------------
//  input are name-value pairs
//----------------------------------------------------------------------------
-(NSMutableDictionary *)attributesWithPairs:(id)firstArg :(va_list)args
{
  NSMutableDictionary * attributes = [[NSMutableDictionary alloc] init];
  
  NSString * name = nil;
  for (id arg = firstArg; arg != nil; arg = va_arg(args, id))
  {
    if (name == nil)
    {
      name = arg;
      continue;
    }
    
    [attributes setObject:arg forKey:name];
    name = nil;
  }
  
  return attributes;
}

//----------------------------------------------------------------------------
- (void)setAttributes:(NSMutableDictionary *)attributes forRow:(MVRow *)row
{
  NSParameterAssert(row != nil);
  
  if (row.dirty)
  {
    [attributes addEntriesFromDictionary:row.attributes];
  }
  
  row.attributes = attributes;
  row.dirty = YES;
}

//----------------------------------------------------------------------------
- (void)setAttributes:(id)firstArg, ... 
{
  va_list args;
  va_start(args, firstArg);
  NSMutableDictionary * attributes = [self attributesWithPairs:firstArg:args];
  va_end(args);

  MVRow * row = [rows lastObject];
  [self setAttributes:attributes forRow:row];

  // update saved
  [archiver addObjectToSave:row];
}

//----------------------------------------------------------------------------
- (void)setAttributesForRowIndex:(NSUInteger)index :(id)firstArg, ...
{
  va_list args;
  va_start(args, firstArg);
  NSMutableDictionary * attributes = [self attributesWithPairs:firstArg:args];
  va_end(args);
  
  MVRow * row = [rows objectAtIndex:index];
  [self setAttributes:attributes forRow:row];

  // update saved
  [archiver addObjectToSave:row];
}

//----------------------------------------------------------------------------
- (void)setAttributesFromRowIndex:(NSUInteger)index :(id)firstArg, ...
{
  va_list args;
  va_start(args, firstArg);
  NSDictionary * attributes = [self attributesWithPairs:firstArg:args];
  va_end(args);

  for (NSUInteger numRows = [rows count]; index < numRows; ++index)
  {
    MVRow * row = [rows objectAtIndex:index];
    [self setAttributes:[NSMutableDictionary dictionaryWithDictionary:attributes] forRow:row];

    // update saved
    [archiver addObjectToSave:row];
  }
}

//----------------------------------------------------------------------------
- (void) applyFilter: (NSString *)filter
{
  [tableLock lock];
  if (filter == nil || [filter length] == 0)
  {
    // copy everything (copy by elems because want to exclude later added rows)
    displayRows = [NSMutableArray arrayWithArray:rows];
    
    /*
    displayRows = [[NSMutableArray alloc] init];
    for (MVRow * row in rows)
    {
      if (row.isSaved)
      {
        [displayRows addObject:row];
      }
    }
     */
    
  }
  else
  {
    NSPredicate *predicate = [NSPredicate
                              predicateWithFormat:@"self contains[cd] %@", filter];

    displayRows = [[NSMutableArray alloc] init];
    for (MVRow * row in rows)
    {
      if (row.coloumns == nil)
      {
        [row loadFromFile:swapFile];
      }
    
      NSString * metadata = [row.attributes objectForKey:MVMetaDataAttributeName];
      if (metadata == nil || [predicate evaluateWithObject:metadata] == YES)
      {
        [displayRows addObject:row];
      }
    }
  }
  [tableLock unlock];
}

//----------------------------------------------------------------------------
- (void)sortByOffset
{
  [tableLock lock];
  [rows sortWithOptions:NSSortStable usingComparator:^(id obj1, id obj2)   
   {
     MVRow * row1 = obj1;
     MVRow * row2 = obj2;
     if (row1.offset < row2.offset) return (NSComparisonResult)NSOrderedAscending;
     if (row1.offset > row2.offset) return (NSComparisonResult)NSOrderedDescending;
     return (NSComparisonResult)NSOrderedSame;
   }];
  [tableLock unlock]; 
}

//----------------------------------------------------------------------------
- (void)saveIndexes
{
  uint32_t rowCount = [rows count];
  fwrite(&rowCount, sizeof(uint32_t), 1, swapFile);

  for (MVRow * row in rows)
  {
    [row saveIndexToFile:swapFile];
  }
}

//----------------------------------------------------------------------------
- (void)loadIndexes
{
  uint32_t rowCount;
  fread(&rowCount, sizeof(uint32_t), 1, swapFile);
  
  while (rowCount-- > 0)
  {
    MVRow * row = [[MVRow alloc] init];
    [row loadIndexFromFile:swapFile];
    [rows addObject:row];
  }
}

@end


//============================================================================
@implementation MVNode

@synthesize caption, parent, dataRange, details, userInfo, detailsOffset;

//-----------------------------------------------------------------------------
-(id)init
{
  if (self = [super init]) 
  {
    children = [[NSMutableArray alloc] init];
    userInfo = [[NSMutableDictionary alloc] init];
  }
  return self;
}

//----------------------------------------------------------------------------
-(NSString *)description
{
  return [[super description] stringByAppendingFormat:@" [%@]", caption];
}

//----------------------------------------------------------------------------
- (MVNode *)childAtIndex:(NSUInteger)n 
{
  return [children objectAtIndex:n];
}

//----------------------------------------------------------------------------
- (NSUInteger)numberOfChildren 
{
  return [children count];
}

//----------------------------------------------------------------------------
- (void)insertNode:(MVNode *)node
{
  MVLayout * layout = [userInfo objectForKey:MVLayoutUserInfoKey];
  
  [layout.dataController.treeLock lock];
  
  NSUInteger index = [children indexOfObjectPassingTest:
                      ^(id obj, NSUInteger idx, BOOL *stop)
                      {
                        if (node.dataRange.location < [obj dataRange].location)
                        {
                          *stop = YES;
                          return YES;
                        }
                        return NO;
                      }];
  
  NSNotificationCenter * nc = [NSNotificationCenter defaultCenter];
  [nc postNotificationName:MVDataTreeWillChangeNotification 
                    object:layout.dataController];

  if (index == NSNotFound)
  {
    [children addObject:node];
  }
  else
  {
    [children insertObject:node atIndex:index];
  }

  [nc postNotificationName:MVDataTreeDidChangeNotification 
                    object:layout.dataController];

  [layout.dataController updateTreeView:self];
  
  [layout.dataController.treeLock unlock];
}

//----------------------------------------------------------------------------
- (MVNode *)insertChild:(NSString *)_caption
            location:(uint32_t)location 
              length:(uint32_t)length
{
  MVNode * node = [[MVNode alloc] init];
  node.caption = _caption;
  node.dataRange = NSMakeRange(location,length);
  node.parent = self;
  [node.userInfo addEntriesFromDictionary:userInfo];
  [self insertNode:node]; 
  return node;
}

//----------------------------------------------------------------------------
- (MVNode *)insertChildWithDetails:(NSString *)_caption 
                       location:(uint32_t)location 
                         length:(uint32_t)length
                          saver:(MVNodeSaver &)saver
{
  MVNode * node = [self insertChild:_caption location:location length:length];
  MVLayout * layout = [userInfo objectForKey:MVLayoutUserInfoKey];
  node.details = [MVTable tableWithArchiver:layout.archiver];
  saver.setNode(node);
  return node;
}

//----------------------------------------------------------------------------
- (MVNode *)findNodeByUserInfo:(NSDictionary *)uinfo
{
  // act node
  if ([userInfo isEqualToDictionary:uinfo] == YES)
  {
    return self;
  }

  // recursively on childrens
  for (MVNode * node in children)
  {
    MVNode * found = [node findNodeByUserInfo:uinfo];
    if (found != nil)
    {
      return found;
    }
  }
  
  // give up
  return nil;
}

//-----------------------------------------------------------------------------
- (void)openDetails
{
  MVLayout * layout = [userInfo objectForKey:MVLayoutUserInfoKey];
  FILE * pFile = fopen(CSTRING(layout.archiver.swapPath), "r");
  if (pFile != NULL)
  {
    if (details != nil) // saving in progress
    {
      details.swapFile = pFile;
    }
    else if (detailsOffset != 0) // saved and has content
    {
      [self loadFromFile:pFile];
    }
  }
}

//-----------------------------------------------------------------------------
- (void)closeDetails
{
  if (details.swapFile != NULL)
  {
    fclose(details.swapFile);
    details.swapFile = NULL;
  }
}

//-----------------------------------------------------------------------------
- (void)sortDetails
{
  MVLayout * layout = [userInfo objectForKey:MVLayoutUserInfoKey];
  [layout.dataController updateStatus:MVStatusTaskStarted];
  [details sortByOffset];
  [layout.dataController updateStatus:MVStatusTaskTerminated];
}

//----------------------------------------------------------------------------
- (void)filterDetails: (NSString *)filter
{
  MVLayout * layout = [userInfo objectForKey:MVLayoutUserInfoKey];
  [layout.dataController updateStatus:MVStatusTaskStarted];
  [layout.archiver suspend];
  [details applyFilter:filter];
  [layout.archiver resume];
  [layout.dataController updateStatus:MVStatusTaskTerminated];
}

//-----------------------------------------------------------------------------
- (void)saveToFile:(FILE *)pFile
{
  MVLayout * layout = [userInfo objectForKey:MVLayoutUserInfoKey];
  [layout.dataController updateStatus:MVStatusTaskStarted];
  
  uint32_t filePos = ftell(pFile);
  details.swapFile = pFile;
  [details saveIndexes];
  detailsOffset = filePos; 
  
  // clear the * prefix 
  [layout.dataController updateTreeView:self];
  
  // update the details table
  if (self == layout.dataController.selectedNode)
  {
    [self openDetails];
    [details applyFilter:nil];
  }
  
  [layout.dataController updateStatus:MVStatusTaskTerminated];
}
	
//-----------------------------------------------------------------------------
- (void)loadFromFile:(FILE *)pFile
{
  MVLayout * layout = [userInfo objectForKey:MVLayoutUserInfoKey];
  [layout.dataController updateStatus:MVStatusTaskStarted];
  details = [MVTable tableWithArchiver:layout.archiver];
  details.swapFile = pFile;
  NSParameterAssert(detailsOffset != 0);
  fseek (pFile, detailsOffset, SEEK_SET);
  [details loadIndexes];
  [layout.dataController updateStatus:MVStatusTaskTerminated];
}

//-----------------------------------------------------------------------------
-(void)clear
{
  MVLayout * layout = [userInfo objectForKey:MVLayoutUserInfoKey];
  if (layout.dataController.selectedNode != self)
  {
    details = nil;
  }
}

@end


//============================================================================
@implementation MVDataController

@synthesize fileName, fileData, realData, layouts, rootNode, selectedNode, treeLock;

//-----------------------------------------------------------------------------
/*
- (void)dealloc
{
  NSLog(@"********MVDataController deallocated: %@", self);
  for (MVLayout * layout in layouts)
  {
    NSLog(@"%@ Retain count is %ld", layout, CFGetRetainCount((__bridge CFTypeRef)layout));
  }
}
*/

//-----------------------------------------------------------------------------
-(id)init
{
  if (self = [super init]) 
  {
    layouts = [[NSMutableArray alloc] init];
    rootNode = [[MVNode alloc] init];
    treeLock = [[NSLock alloc] init];
  }
  return self;
}

//----------------------------------------------------------------------------
-(NSString *)getMachine:(cpu_type_t)cputype
{
  switch (cputype)
  {
    default:                  return @"???"; 
    case CPU_TYPE_I386:       return @"X86";
    case CPU_TYPE_POWERPC:    return @"PPC";
    case CPU_TYPE_X86_64:     return @"X86_64";
    case CPU_TYPE_POWERPC64:  return @"PPC64";
    case CPU_TYPE_ARM:        return @"ARM";  
    case CPU_TYPE_ARM64:      return @"ARM64";
  }
}

//----------------------------------------------------------------------------
-(NSString *)getARMCpu:(cpu_subtype_t)cpusubtype
{
  switch (cpusubtype)
  {
    default:                      return @"???"; 
    case CPU_SUBTYPE_ARM_ALL:     return @"ARM_ALL";
    case CPU_SUBTYPE_ARM_V4T:     return @"ARM_V4T";
    case CPU_SUBTYPE_ARM_V6:      return @"ARM_V6";
    case CPU_SUBTYPE_ARM_V5TEJ:   return @"ARM_V5TEJ";
    case CPU_SUBTYPE_ARM_XSCALE:  return @"ARM_XSCALE";
    case CPU_SUBTYPE_ARM_V7:      return @"ARM_V7";
    case CPU_SUBTYPE_ARM_V7F:     return @"ARM_V7F";
    case CPU_SUBTYPE_ARM_V7K:     return @"ARM_V7K";
    case CPU_SUBTYPE_ARM_V7S:     return @"ARM_V7S";
    case CPU_SUBTYPE_ARM_V8:      return @"ARM_V8";
  }
}

//----------------------------------------------------------------------------
-(NSString *)getARM64Cpu:(cpu_subtype_t)cpusubtype
{
  switch (cpusubtype)
  {
    default:                      return @"???";
    case CPU_SUBTYPE_ARM64_ALL:   return @"ARM64_ALL";
    case CPU_SUBTYPE_ARM64_V8:    return @"ARM64_V8";
  }
}

//----------------------------------------------------------------------------
-(BOOL)isSupportedMachine:(NSString *)machine
{
  return ([machine isEqualToString:@"X86"] == YES ||
          [machine isEqualToString:@"X86_64"] == YES ||
          [machine isEqualToString:@"ARM"] == YES ||
          [machine isEqualToString:@"ARM64"] == YES);
}

//----------------------------------------------------------------------------
-(void)createMachOLayout:(MVNode *)node
             mach_header:(struct mach_header const *)mach_header
{
  NSString * machine = [self getMachine:mach_header->cputype];
  
  node.caption = [NSString stringWithFormat:@"%@ (%@)",
                  mach_header->filetype == MH_OBJECT      ? @"Object " :
                  mach_header->filetype == MH_EXECUTE     ? @"Executable " :
                  mach_header->filetype == MH_FVMLIB      ? @"Fixed VM Shared Library" :
                  mach_header->filetype == MH_CORE        ? @"Core" :
                  mach_header->filetype == MH_PRELOAD     ? @"Preloaded Executable" :
                  mach_header->filetype == MH_DYLIB       ? @"Shared Library " : 
                  mach_header->filetype == MH_DYLINKER    ? @"Dynamic Link Editor" :
                  mach_header->filetype == MH_BUNDLE      ? @"Bundle" : 
                  mach_header->filetype == MH_DYLIB_STUB  ? @"Shared Library Stub" : 
                  mach_header->filetype == MH_DSYM        ? @"Debug Symbols" : 
                  mach_header->filetype == MH_KEXT_BUNDLE ? @"Kernel Extension" : @"?????",
                  [machine isEqualToString:@"ARM"] == YES ? [self getARMCpu:mach_header->cpusubtype] : machine];
  
  MachOLayout * layout = [MachOLayout layoutWithDataController:self rootNode:node];
                          
  [node.userInfo setObject:layout forKey:MVLayoutUserInfoKey];
  
  if ([self isSupportedMachine:machine])
  {
    [layouts addObject:layout];
  }
  else
  {
    // there is no detail to extract
    [layout.archiver halt];
  }
}

//----------------------------------------------------------------------------
-(void)createMachO64Layout:(MVNode *)node
            mach_header_64:(struct mach_header_64 const *)mach_header_64
{
  NSString * machine = [self getMachine:mach_header_64->cputype];

  node.caption = [NSString stringWithFormat:@"%@ (%@)",
                  mach_header_64->filetype == MH_OBJECT      ? @"Object " :
                  mach_header_64->filetype == MH_EXECUTE     ? @"Executable " :
                  mach_header_64->filetype == MH_FVMLIB      ? @"Fixed VM Shared Library" :
                  mach_header_64->filetype == MH_CORE        ? @"Core" :
                  mach_header_64->filetype == MH_PRELOAD     ? @"Preloaded Executable" :
                  mach_header_64->filetype == MH_DYLIB       ? @"Shared Library " :
                  mach_header_64->filetype == MH_DYLINKER    ? @"Dynamic Link Editor" :
                  mach_header_64->filetype == MH_BUNDLE      ? @"Bundle" :
                  mach_header_64->filetype == MH_DYLIB_STUB  ? @"Shared Library Stub" :
                  mach_header_64->filetype == MH_DSYM        ? @"Debug Symbols" :
                  mach_header_64->filetype == MH_KEXT_BUNDLE ? @"Kernel Extension" : @"?????",
                  [machine isEqualToString:@"ARM64"] == YES ? [self getARM64Cpu:mach_header_64->cpusubtype] : machine];
  
  MachOLayout * layout = [MachOLayout layoutWithDataController:self rootNode:node];

  [node.userInfo setObject:layout forKey:MVLayoutUserInfoKey];

  if ([self isSupportedMachine:machine])
  {
    [layouts addObject:layout];
  }
  else
  {
    // there is no detail to extract
    [layout.archiver halt];
  }
}

//----------------------------------------------------------------------------
-(void)createArchiveLayout:(MVNode *)node machine:(NSString *)machine
{
  node.caption = machine ? [NSString stringWithFormat:@"Static Library (%@)", machine] : @"Static Library";
  
  ArchiveLayout * layout = [ArchiveLayout layoutWithDataController:self rootNode:node];
  
  [node.userInfo setObject:layout forKey:MVLayoutUserInfoKey];
    
  if (machine == nil || [self isSupportedMachine:machine])
    {
    [layouts addObject:layout];
    }
    else
    {
    // there is no detail to extract
    [layout.archiver halt];
  }
}

//----------------------------------------------------------------------------
// create Mach-O layouts based on file headers
- (void)createLayouts:(MVNode *)parent
             location:(uint32_t)location
               length:(uint32_t)length
{
  uint32_t magic = *(uint32_t*)((uint8_t *)[fileData bytes] + location);
  
  switch (magic)
  {
    case FAT_MAGIC:
    case FAT_CIGAM:
    {
      struct fat_header fat_header;
      [fileData getBytes:&fat_header range:NSMakeRange(location, sizeof(struct fat_header))];
      if (magic == FAT_CIGAM)
        swap_fat_header(&fat_header, NX_LittleEndian);
      [self createFatLayout:parent fat_header:&fat_header];
    } break;
      
    case MH_MAGIC:
    case MH_CIGAM:
    {
      struct mach_header mach_header;
      [fileData getBytes:&mach_header range:NSMakeRange(location, sizeof(struct mach_header))];
      if (magic == MH_CIGAM)
        swap_mach_header(&mach_header, NX_LittleEndian);
      [self createMachOLayout:parent mach_header:&mach_header];
    } break;
      
    case MH_MAGIC_64:
    case MH_CIGAM_64:
    {
      struct mach_header_64 mach_header_64;
      [fileData getBytes:&mach_header_64 range:NSMakeRange(location, sizeof(struct mach_header_64))];
      if (magic == MH_CIGAM_64)
        swap_mach_header_64(&mach_header_64, NX_LittleEndian);
      [self createMachO64Layout:parent mach_header_64:&mach_header_64];
    } break;
    
    default:
      [self createArchiveLayout:parent machine:nil];
  }
  
  parent.dataRange = NSMakeRange(location, length);
}

//----------------------------------------------------------------------------
-(void)createFatLayout:(MVNode *)node
            fat_header:(struct fat_header const *)fat_header
{
  node.caption = @"Fat Binary";
  FatLayout * layout = [FatLayout layoutWithDataController:self rootNode:node];
  
  [node.userInfo setObject:layout forKey:MVLayoutUserInfoKey];
  
  [layouts addObject:layout];
  for (uint32_t nimg = 0; nimg < fat_header->nfat_arch; ++nimg)
  {      
    // need to make copy for byte swapping
    struct fat_arch fat_arch;
    [fileData getBytes:&fat_arch range:NSMakeRange(sizeof(struct fat_header) + nimg * sizeof(struct fat_arch), sizeof(struct fat_arch))];
    swap_fat_arch(&fat_arch, 1, NX_LittleEndian);
    
    MVNode * archNode = [node insertChild:nil location:fat_arch.offset length:fat_arch.size];

    if (*(uint64_t*)((uint8_t *)[fileData bytes] + fat_arch.offset) == *(uint64_t*)"!<arch>\n")
    {
      [self createArchiveLayout:archNode machine:[self getMachine:fat_arch.cputype]];
    }
    else
    {
      [self createLayouts:archNode location:fat_arch.offset length:fat_arch.size];
    }
  }
}

//----------------------------------------------------------------------------
- (void)treeViewWillChange
{
  NSNotificationCenter * nc = [NSNotificationCenter defaultCenter];
  [nc postNotificationName:MVDataTreeWillChangeNotification 
                    object:self];
}

//----------------------------------------------------------------------------
- (void)treeViewDidChange
{
  NSNotificationCenter * nc = [NSNotificationCenter defaultCenter];
  [nc postNotificationName:MVDataTreeDidChangeNotification 
                    object:self];
}

//----------------------------------------------------------------------------
- (void)updateTreeView: (MVNode *)node
{
  NSNotificationCenter * nc = [NSNotificationCenter defaultCenter];
  [nc postNotificationName:MVDataTreeChangedNotification 
                    object:self
                  userInfo:node ? [NSDictionary dictionaryWithObject:node forKey:MVNodeUserInfoKey] : nil];
}

//-----------------------------------------------------------------------------
- (void)updateTableView
{
  NSNotificationCenter * nc = [NSNotificationCenter defaultCenter];
  [nc postNotificationName:MVDataTableChangedNotification 
                    object:self];
}

//-----------------------------------------------------------------------------
- (void)updateStatus: (NSString *)status
{
  NSNotificationCenter * nc = [NSNotificationCenter defaultCenter];
  [nc postNotificationName:MVThreadStateChangedNotification 
                    object:self
                  userInfo:[NSDictionary dictionaryWithObject:status forKey:MVStatusUserInfoKey]];
}

@end

#pragma mark -

//============================================================================
@implementation MVArchiver

@synthesize swapPath;

//-----------------------------------------------------------------------------
- (id)init
{
  NSAssert(NO, @"plain init is not allowed");
  return nil;
}

//-----------------------------------------------------------------------------
-(id) initWithPath:(NSString *)path
{  
  if (self = [super init]) 
  {
    objectsToSave = [[NSMutableArray alloc] init];
    
    swapPath = path;
    
    NSLog(@"%@: swap file is being created:%@", self, swapPath);
    FILE * pFile = fopen(CSTRING(swapPath), "w");
    if (pFile == NULL)
    {
      NSLog(@"*** file cannot be created: %@ '%s'", swapPath,strerror(errno));
      return nil;
    }    
    fputs("!<MachoViewSwapFile 1.0>\n", pFile); // header for versioning
    fclose(pFile);
    
    saverLock = [[NSLock alloc] init];

#ifndef MV_NO_ARCHIVER
    saverThread = [[NSThread alloc] initWithTarget:self selector:@selector(doSave) object:nil];
    [saverThread start];
    NSLog(@"********MVArchiver started: %@", self);
#endif    
  }
  return self;
}

//-----------------------------------------------------------------------------
+(MVArchiver *) archiverWithPath:(NSString *)path
{
  return [[MVArchiver alloc] initWithPath:path];
}

//-----------------------------------------------------------------------------
-(void) suspend
{
  [saverLock lock];
}

//-----------------------------------------------------------------------------
-(void) resume
{
  [saverLock unlock];
}

//-----------------------------------------------------------------------------
-(void) halt
{
  [saverThread cancel];
  NSLog(@"********MVArchiver halted: %@", self);
}

//-----------------------------------------------------------------------------
-(void) addObjectToSave:(id)object;
{
  NSParameterAssert([object conformsToProtocol:@protocol(MVSerializing)] == YES);
  
  [saverLock lock];
  [objectsToSave addObject:object];
  [saverLock unlock];
  
  // if the background saver thread has been cancelled, then do do one cycle manually
  if ([saverThread isCancelled])
  {
    [self doSave];
  }
}

//-----------------------------------------------------------------------------
-(void) doSave
{
  for (;;)
  {
    if ([objectsToSave count] > 0)
    {
      [pipeCondition lock];
      ++numIOThread;
      [pipeCondition unlock];
        
      FILE * pFile = fopen(CSTRING(swapPath), "a+");
      if (pFile != NULL)
      { 
        [saverLock lock];

#if DEBUG
        NSLog(@"%@: saving %lu rows",[NSThread currentThread],(unsigned long)[objectsToSave count]);
#endif
        for (id <MVSerializing> serializable in objectsToSave)
        {
          [serializable saveToFile:pFile];
        }
        fclose(pFile);

        for (id <MVSerializing> serializable in objectsToSave)
        {
          [serializable clear];
        }
        
        // reset buffer
        objectsToSave = [[NSMutableArray alloc] init];

        [saverLock unlock];
      }

      [pipeCondition lock];
      --numIOThread;
      [pipeCondition signal];
      [pipeCondition unlock];
    }
    
    if ([saverThread isCancelled])
    {
    // only exit if buffer is surely empty
      if ([objectsToSave count] == 0)
    {
      break; // the nicest way
      //return;
      //[NSThread exit];
    }
      // do not wait for new rows if the saver has been cancelled
      // just flush out the existing ones
      continue;
    }
    
    // let's wait for some objects to collect for saving
    double rnd = 1. + rand()/((double)RAND_MAX+1); // between 1 and 2
    [NSThread sleepForTimeInterval:rnd];
  }
}

@end

//-----------------------------------------------------------------------------
MVNodeSaver::MVNodeSaver() 
  : m_node(nil) 
{
}

//-----------------------------------------------------------------------------
MVNodeSaver::~MVNodeSaver() 
{
  MVLayout * layout = [m_node.userInfo objectForKey:MVLayoutUserInfoKey];
  [layout.archiver addObjectToSave:m_node];
}
