/*
 *  PreferencesWindowController.mm
 *  MachOView
 *
 *  Created by psaghelyi on 12/24/12.
 *
 */

#import "PreferenceController.h"

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

@end

