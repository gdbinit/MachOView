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
  self = [super initWithWindowNibName:@"Preferences"];
  return self;
}

- (IBAction)toggleOpenAtLaunch:(id)sender
{
  // nothing to do here?
}

@end

