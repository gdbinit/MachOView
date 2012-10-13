/*
 *  DyldInfo.h
 *  MachOView
 *
 *  Created by psaghelyi on 21/09/2010.
 *
 */

#import "MachOLayout.h"


@interface DyldHelper : NSObject
{
  NSMutableDictionary * externalMap; // external symbol name --> symbols index (negative number)
}

+(DyldHelper *) dyldHelperWithSymbols:(NSDictionary *)symbolNames is64Bit:(bool)is64Bit;

@end


@interface MachOLayout (DyldInfo)

enum BindNodeType {NodeTypeBind, NodeTypeWeakBind, NodeTypeLazyBind};

- (MVNode *)createRebaseNode:(MVNode *)parent
                     caption:(NSString *)caption
                    location:(uint32_t)location
                      length:(uint32_t)length
                 baseAddress:(uint64_t)baseAddress;

- (MVNode *)createBindingNode:(MVNode *)parent
                      caption:(NSString *)caption
                     location:(uint32_t)location
                       length:(uint32_t)length
                  baseAddress:(uint64_t)baseAddress
                     nodeType:(BindNodeType)nodeType
                   dyldHelper:(DyldHelper *)helper;

- (MVNode *)createExportNode:(MVNode *)parent
                     caption:(NSString *)caption
                    location:(uint32_t)location
                      length:(uint32_t)length
                 baseAddress:(uint64_t)baseAddress;

@end
