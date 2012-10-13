/*
 *  LoadCommands.h
 *  MachOView
 *
 *  Created by psaghelyi on 20/07/2010.
 *
 */

#import "MachOLayout.h"


@interface MachOLayout (LoadCommands)

- (NSString *)getNameForCommand:(uint32_t)cmd;

-(MVNode *)createLoadCommandNode:(MVNode *)parent
                         caption:(NSString *)caption
                        location:(uint32_t)location
                          length:(uint32_t)length
                         command:(uint32_t)command;

@end
