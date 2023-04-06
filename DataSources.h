/*
 *  DataSources.h
 *  MachOView
 *
 *  Created by psaghelyi on 15/06/2010.
 *
 */

extern NSString * const MVScannerErrorMessage;

@interface MVDataSourceTree : NSObject;
@end


@interface MVDataSourceDetails : NSObject;
- (NSString *)fullBinaryData:(NSTableView *)tableView;
- (NSString *)fullDetailData:(NSTableView *)tableView;
@end

