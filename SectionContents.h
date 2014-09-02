/*
 *  SectionContents.h
 *  MachOView
 *
 *  Created by psaghelyi on 15/09/2010.
 *
 */

#import "MachOLayout.h"

@interface MachOLayout (SectionContents)

- (MVNode *)createPointersNode:(MVNode *)parent
                       caption:(NSString *)caption
                      location:(uint32_t)location
                        length:(uint32_t)length;


- (MVNode *)createPointers64Node:(MVNode *)parent
                         caption:(NSString *)caption
                        location:(uint32_t)location
                          length:(uint32_t)length;

-(MVNode *)createCStringsNode:(MVNode *)parent
                      caption:(NSString *)caption
                     location:(uint32_t)location
                       length:(uint32_t)length;

-(MVNode *)createLiteralsNode:(MVNode *)parent
                      caption:(NSString *)caption
                     location:(uint32_t)location
                       length:(uint32_t)length
                       stride:(uint32_t)stride;

- (MVNode *)createIndPointersNode:(MVNode *)parent
                          caption:(NSString *)caption
                         location:(uint32_t)location
                           length:(uint32_t)length;

- (MVNode *)createIndPointers64Node:(MVNode *)parent
                            caption:(NSString *)caption
                           location:(uint32_t)location
                             length:(uint32_t)length;

- (MVNode *)createIndStubsNode:(MVNode *)parent
                       caption:(NSString *)caption
                      location:(uint32_t)location
                        length:(uint32_t)length
                        stride:(uint32_t)stride;

- (MVNode *)createIndStubs64Node:(MVNode *)parent
                         caption:(NSString *)caption
                        location:(uint32_t)location
                          length:(uint32_t)length
                          stride:(uint32_t)stride;

- (MVNode *)createStubHelperNode:(MVNode *)parent
                         caption:(NSString *)caption
                        location:(uint32_t)location
                          length:(uint32_t)length;

- (MVNode *)createTextNode:(MVNode *)parent
                   caption:(NSString *)caption
                  location:(uint32_t)location
                    length:(uint32_t)length
                    reloff:(uint32_t)reloff
                    nreloc:(uint32_t)nreloc
                 extreloff:(uint32_t)extreloff
                   nextrel:(uint32_t)nextrel
                 locreloff:(uint32_t)locreloff
                   nlocrel:(uint32_t)nlocrel;

@end
