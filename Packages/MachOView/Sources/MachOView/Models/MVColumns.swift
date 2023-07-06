//
//  MVColumns.swift
//
//
//  Created by dalong on 2023/6/1.
//

import Foundation

static var nrow_loaded: Int

public enum ColumnProperty: Int {
  case offset = 0
  case data = 1
  case description = 2
  case value = 3
}

@objcMembers
public final class MVColumns: NSObject {
  public let offsetStr: String
  public let dataStr: String
  public let descriptionStr: String
  public let valueStr: String

  public init(offsetStr: String, dataStr: String, descriptionStr: String, valueStr: String) {
    self.offsetStr = offsetStr
    self.dataStr = dataStr
    self.descriptionStr = descriptionStr
    self.valueStr = valueStr
  }
}
@implementation MVColumns

@synthesize offsetStr, dataStr, descriptionStr, valueStr;

//-----------------------------------------------------------------------------
- (instancetype)init
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
+(MVColumns *) columnsWithData:(NSString *)col0 :(NSString *)col1 :(NSString *)col2 :(NSString *)col3
{
  return [[MVColumns alloc] initWithData:col0:col1:col2:col3];
}

//-----------------------------------------------------------------------------
-(void)dealloc
{
#ifdef MV_STATISTICS
  OSAtomicDecrement64(&nrow_loaded);
#endif
}

@end
