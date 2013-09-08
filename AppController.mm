 /*
 *  AppController.mm
 *  MachOView
 *
 *  Created by psaghelyi on 15/06/2010.
 *
 */

#import "Common.h"
#import "AppController.h"
#import "DataController.h"
#import "Document.h"
#import "PreferenceController.h"

// counters for statistics
int64_t nrow_total;  // number of rows (loaded and empty)
int64_t nrow_loaded; // number of loaded rows

//============================================================================
@implementation MVAppController

//----------------------------------------------------------------------------
- (BOOL)applicationShouldOpenUntitledFile:(NSApplication *)sender
{
  return NO;
}

//----------------------------------------------------------------------------
- (BOOL)applicationShouldTerminateAfterLastWindowClosed:(NSApplication *)sender
{
  return NO;
}

//----------------------------------------------------------------------------
- (IBAction)newDocument:(id)sender
{
  NSLog(@"Not yet possible");
}

//----------------------------------------------------------------------------
- (BOOL)isOnlyRunningMachOView
{
  NSProcessInfo * procInfo = [NSProcessInfo processInfo];
  NSBundle * mainBundle = [NSBundle mainBundle];
  NSString * versionString = [mainBundle objectForInfoDictionaryKey:@"CFBundleShortVersionString"];
  
  NSUInteger numberOfInstance = 0;
  
  NSWorkspace * workspace = [NSWorkspace sharedWorkspace];
  for (NSRunningApplication * runningApplication in [workspace runningApplications])
  {
    // check if process name matches
    NSString * fileName = [[runningApplication executableURL] lastPathComponent];
    if ([fileName isEqualToString: [procInfo processName]] == NO)
    {
      continue;
    }

    // check if version string matches
    NSBundle * bundle = [NSBundle bundleWithURL:[runningApplication bundleURL]];
    if ([versionString isEqualToString:[bundle objectForInfoDictionaryKey:@"CFBundleShortVersionString"]] == YES && ++numberOfInstance > 1)
    {
      return NO;
    }
  }
  
  return YES;
}

//----------------------------------------------------------------------------
/* menu item action to attach to a process and read its mach-o header */
- (IBAction)attach:(id)sender
{
}

//----------------------------------------------------------------------------
- (IBAction)openDocument:(id)sender
{
  NSOpenPanel *openPanel = [NSOpenPanel openPanel];
  [openPanel setTreatsFilePackagesAsDirectories:YES];
  [openPanel setAllowsMultipleSelection:YES];
  [openPanel setCanChooseDirectories:NO];
  [openPanel setCanChooseFiles:YES];
  [openPanel setDelegate:self]; // for filtering files in open panel with shouldShowFilename
  [openPanel beginSheetModalForWindow:nil 
   completionHandler:^(NSInteger result) 
   {
     if (result != NSOKButton) 
     {
       return;
     }
     [openPanel orderOut:self]; // close panel before we might present an error
     for (NSURL * url in [openPanel URLs])
     {
       [self application:NSApp openFile:[url path]];
     }
   }];
}

//----------------------------------------------------------------------------
- (BOOL)panel:(id)sender shouldShowFilename:(NSString*)filename
{
  NSURL * url = [NSURL fileURLWithPath:filename];

  // can enter directories
  NSNumber * isDirectory = nil;
  [url getResourceValue:&isDirectory forKey:NSURLIsDirectoryKey error:NULL];
  if ([isDirectory boolValue] == YES) 
  {
    return YES;
  }

  // skip symbolic links, etc.
  NSNumber * isRegularFile = nil;
  [url getResourceValue:&isRegularFile forKey:NSURLIsRegularFileKey error:NULL];
  if ([isRegularFile boolValue] == NO) 
  {
    return NO;
  }
  
  // check for magic values at front
  NSFileHandle * fileHandle = [NSFileHandle fileHandleForReadingAtPath:filename];
  NSData * magicData = [fileHandle readDataOfLength:8];
  [fileHandle closeFile];
  
  if ([magicData length] < sizeof(uint32_t))
  {
    return NO;
  }
  
  uint32_t magic = *(uint32_t*)[magicData bytes];
  if (magic == MH_MAGIC || magic == MH_MAGIC_64 || 
      magic == FAT_CIGAM || magic == FAT_MAGIC)
  {
    return YES;
  }
  
  if ([magicData length] < sizeof(uint64_t))
  {
    return NO;
  }
  
  if (*(uint64_t*)[magicData bytes] == *(uint64_t*)"!<arch>\n")
  {
    return YES;
  }
  
  return NO;
}

//----------------------------------------------------------------------------
- (void)applicationWillFinishLaunching:(NSNotification *)aNotification
{
  BOOL isFirstMachOView = [self isOnlyRunningMachOView];
  
  // disable the state resume feature, it's not very useful with MachOView
  if([[NSUserDefaults standardUserDefaults] objectForKey: @"ApplePersistenceIgnoreState"] == nil)
      [[NSUserDefaults standardUserDefaults] setBool: YES forKey:@"ApplePersistenceIgnoreState"];

  // load user's defaults for preferences
  if([[NSUserDefaults standardUserDefaults] objectForKey: @"UseLLVMDisassembler"] != nil)
    qflag = [[NSUserDefaults standardUserDefaults] boolForKey:@"UseLLVMDisassembler"];

  
  NSFileManager * fileManager = [NSFileManager defaultManager];
  NSString * tempDir = [MVDocument temporaryDirectory];
  
  __autoreleasing NSError * error;
  
  // remove previously forgotten temporary files
  if (isFirstMachOView && [fileManager fileExistsAtPath:tempDir isDirectory:NULL] == YES)
  {
    if ([fileManager removeItemAtPath:tempDir error:&error] == NO)
    {
      [NSApp presentError:error];
    }
  }
  
  // create placeholder for temporary files
  if ([fileManager fileExistsAtPath:tempDir isDirectory:NULL] == NO)
  {
    if ([fileManager createDirectoryAtPath:tempDir
               withIntermediateDirectories:NO
                                attributes:nil
                                     error:&error] == NO)
    {
      [NSApp presentError:error];
    }
  }
}

//----------------------------------------------------------------------------
- (void)applicationDidFinishLaunching:(NSNotification *)aNotification 
{
#ifdef MV_STATISTICS
  nrow_total = nrow_loaded = 0;
  [NSThread detachNewThreadSelector:@selector(printStat) toTarget:self withObject:nil];
#endif 
  
  // if there is no document yet, then pop up an open file dialogue  
  if ([[[NSDocumentController sharedDocumentController] documents] count] == 0)
  {
    [self openDocument:nil];
  }
}

//----------------------------------------------------------------------------
- (void)applicationWillTerminate:(NSNotification *)aNotification
{
  BOOL isLastMachOView = [self isOnlyRunningMachOView];
  
  if (isLastMachOView == YES)
  {
    // remove temporary files
    NSFileManager * fileManager = [NSFileManager defaultManager];
    NSString * tempDir = [MVDocument temporaryDirectory];
    [fileManager removeItemAtPath:tempDir error:NULL];
  }
}

//----------------------------------------------------------------------------
- (BOOL)application:(NSApplication *)theApplication openFile:(NSString *)filename
{
  NSLog (@"open file: %@", filename);
  
  __autoreleasing NSError *error;

  NSDocumentController * documentController = [NSDocumentController sharedDocumentController];
  MVDocument * document = [documentController openDocumentWithContentsOfURL:[NSURL fileURLWithPath:filename] 
                                                                    display:YES 
                                                                      error:&error];

  // If we can't open the document, present error to the user
  if (!document) 
  {
    [NSApp presentError:error];
    return NO;
  }
  
  return YES;
}

//----------------------------------------------------------------------------
-(void) printStat
{
  for (;;)
  {
    NSLog(@"stat: %lld/%lld rows in memory\n",nrow_loaded,nrow_total);
    [NSThread sleepForTimeInterval:1];
  }
}

//----------------------------------------------------------------------------
- (IBAction)showPreferencePanel:(id)sender
{
    if (!preferenceController)
    {
        preferenceController = [[MVPreferenceController alloc] init];
    }
    [preferenceController showWindow:self];
}

@end


