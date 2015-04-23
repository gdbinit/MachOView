/*
 *  ReadWrite.h
 *  MachOView
 *
 *  Created by psaghelyi on 20/07/2010.
 *
 */

#import "DataController.h"
@interface MVDataController (ReadWrite)


- (uint8_t)     read_uint8:(NSRange &)range;
- (uint16_t)    read_uint16:(NSRange &)range;  
- (uint32_t)    read_uint32:(NSRange &)range; 
- (uint64_t)    read_uint64:(NSRange &)range; 
- (int8_t)      read_int8:(NSRange &)range; 
- (int16_t)     read_int16:(NSRange &)range;   
- (int32_t)     read_int32:(NSRange &)range;  
- (int64_t)     read_int64:(NSRange &)range;

- (uint8_t)     read_uint8:(NSRange &)range   lastReadHex:(NSString * __autoreleasing *)lastReadHex;
- (uint16_t)    read_uint16:(NSRange &)range  lastReadHex:(NSString * __autoreleasing *)lastReadHex;
- (uint32_t)    read_uint32:(NSRange &)range  lastReadHex:(NSString * __autoreleasing *)lastReadHex;
- (uint64_t)    read_uint64:(NSRange &)range  lastReadHex:(NSString * __autoreleasing *)lastReadHex;
- (int8_t)      read_int8:(NSRange &)range    lastReadHex:(NSString * __autoreleasing *)lastReadHex;
- (int16_t)     read_int16:(NSRange &)range   lastReadHex:(NSString * __autoreleasing *)lastReadHex;
- (int32_t)     read_int32:(NSRange &)range   lastReadHex:(NSString * __autoreleasing *)lastReadHex;
- (int64_t)     read_int64:(NSRange &)range   lastReadHex:(NSString * __autoreleasing *)lastReadHex;

- (NSString *)  read_string:(NSRange &)range;
- (NSString *)  read_string:(NSRange &)range  fixlen:(NSUInteger)len;
- (NSData *)    read_bytes:(NSRange &)range   length:(NSUInteger)length;
- (int64_t)     read_sleb128:(NSRange &)range;
- (uint64_t)    read_uleb128:(NSRange &)range;

- (NSString *)  read_string:(NSRange &)range  lastReadHex:(NSString * __autoreleasing *)lastReadHex;
- (NSString *)  read_string:(NSRange &)range  fixlen:(NSUInteger)len lastReadHex:(NSString * __autoreleasing *)lastReadHex;
- (NSData *)    read_bytes:(NSRange &)range   length:(NSUInteger)length lastReadHex:(NSString * __autoreleasing *)lastReadHex;
- (int64_t)     read_sleb128:(NSRange &)range lastReadHex:(NSString * __autoreleasing *)lastReadHex;
- (uint64_t)    read_uleb128:(NSRange &)range lastReadHex:(NSString * __autoreleasing *)lastReadHex;

- (void)        write_uint8:(NSUInteger)location data:(uint8_t)data;
- (void)        write_uint16:(NSUInteger)location data:(uint16_t)data;
- (void)        write_uint32:(NSUInteger)location data:(uint32_t)data;
- (void)        write_uint64:(NSUInteger)location data:(uint64_t)data;
- (void)        write_int8:(NSUInteger)location data:(int8_t)data;
- (void)        write_int16:(NSUInteger)location data:(int16_t)data;
- (void)        write_int32:(NSUInteger)location data:(int32_t)data;
- (void)        write_int64:(NSUInteger)location data:(int64_t)data;
- (void)        write_string:(NSUInteger)location data:(NSString *)data;
- (void)        write_bytes:(NSUInteger)location data:(NSData *)data;
- (void)        write_sleb128:(NSUInteger)location data:(int64_t)data;
- (void)        write_uleb128:(NSUInteger)location data:(uint64_t)data;

@end
