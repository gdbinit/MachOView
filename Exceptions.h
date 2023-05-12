/*
 *  Exceptions.h
 *  MachOView
 *
 *  Created by psaghelyi on 20/07/2010.
 *
 */

#import "MachOLayout.h"

@interface MachOLayout (Exceptions)

- (MVNode *)createCFINode:(MVNode *)parent
                  caption:(NSString *)caption
                 location:(uint64_t)location
                   length:(uint64_t)length;


- (MVNode *)createLSDANode:(MVNode *)parent
                 caption:(NSString *)caption
                location:(uint64_t)location
                  length:(uint64_t)length
          eh_frame_begin:(uint64_t)eh_frame_begin;

- (MVNode *)createUnwindInfoHeaderNode:(MVNode *)parent
                               caption:(NSString *)caption
                              location:(uint64_t)location
                                header:(struct unwind_info_section_header const *)unwind_info_section_header;


@end
