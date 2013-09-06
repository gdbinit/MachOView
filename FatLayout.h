/*
 *  FatLayout.h
 *  MachOView
 *
 *  Created by psaghelyi on 02/12/2011.
 *
 */

#import "Layout.h"

@interface FatLayout : MVLayout;

+ (FatLayout *)     layoutWithDataController:(MVDataController *)dc rootNode:(MVNode *)node;

@end

