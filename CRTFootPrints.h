/*
 *  CRTFootPrints.h
 *  MachOView
 *
 *  Created by psaghelyi on 25/11/2010.
 *
 */


#import "MachOLayout.h"

#define FOOTPRINT_STRIDE 16
#define GAP(x)  {00, x}  // fake entry with zero length, second element is the size of bytes to skip

typedef uint8_t AsmFootPrint[][FOOTPRINT_STRIDE];

@interface MachOLayout (CRTFootPrints)

- (bool) matchAsmAtOffset:(uint32_t)offset 
             asmFootPrint:(const AsmFootPrint)footprint 
                lineCount:(NSUInteger)lineCount;
                
- (void) determineRuntimeVersion;

@end

    


