//
//  MVTable.swift
//  
//
//  Created by dalong on 2023/6/1.
//

import Foundation

public final class MVTable: NSObject {
    
}
@interface MVTable : NSObject
{
  NSMutableArray *      rows;         // array of MVRow * (host of all the rows)
  NSMutableArray *      displayRows;  // array of MVRow * (rows filtered by search criteria)
  MVArchiver *          __weak archiver;
  FILE *                swapFile;
  NSLock *              tableLock;
}

@property (nonatomic)   FILE * swapFile;

- (NSUInteger)          rowCountToDisplay;
- (MVRow *)             getRowToDisplay:(NSUInteger)rowIndex;

- (void)                popRow;
- (void)                appendRow:(id)col0 :(id)col1 :(id)col2 :(id)col3;
- (void)                insertRowWithOffset:(uint64_t)offset :(id)col0 :(id)col1 :(id)col2 :(id)col3;
- (void)                updateCellContentTo:(id)object atRow:(NSUInteger)rowIndex andCol:(NSUInteger)colIndex;

- (NSUInteger)          rowCount;
- (void)                setAttributes:(NSString *)firstArg, ... NS_REQUIRES_NIL_TERMINATION;
- (void)                setAttributesForRowIndex:(NSUInteger)index :(NSString *)firstArg, ... NS_REQUIRES_NIL_TERMINATION;
- (void)                setAttributesFromRowIndex:(NSUInteger)index :(NSString *)firstArg, ... NS_REQUIRES_NIL_TERMINATION;

@end
