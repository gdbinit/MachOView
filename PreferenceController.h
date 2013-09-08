/*
 *  MVPreferenceController.h
 *  MachOView
 *
 *  Created by psaghelyi on 12/24/12.
 *
 */

#include "disasm.h"

@interface MVPreferenceController: NSWindowController
{
  IBOutlet NSButton *   useLLVMDisassembler;
  IBOutlet NSButton *   openAtLaunch;
}

- (IBAction)toggleUseLLVMDisassembler:(id)sender;
- (IBAction)toggleOpenAtLaunch:(id)sender;

@end