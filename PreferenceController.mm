/*
 *  PreferencesWindowController.mm
 *  MachOView
 *
 *  Created by psaghelyi on 12/24/12.
 *
 */

#import "PreferenceController.h"

#include "disasm.h" // for the disassembler flags

@implementation MVPreferenceController

-(id)init
{
  if (![super initWithWindowNibName:@"Preferences"])
    return nil;
  
  return self;
}

- (IBAction)toggleUseLLVMDisassembler:(id)sender
{
  qflag = ([useLLVMDisassembler state] == NSOnState);
}

- (IBAction)toggleOpenAtLaunch:(id)sender
{
  // nothing to do here?
}

@end

