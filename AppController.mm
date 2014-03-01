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
#import "Attach.h"

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
/* 
 * menu item action to attach to a process and read its mach-o header
 */
- (IBAction)attach:(id)sender
{
  NSAlert *alert = [NSAlert alertWithMessageText:@"Insert PID to attach to:"
                                   defaultButton:@"Attach"
                                 alternateButton:@"Cancel"
                                     otherButton:nil
                       informativeTextWithFormat:@""];
  
  NSTextField *input = [[NSTextField alloc] initWithFrame:NSMakeRect(0, 0, 200, 24)];
  [input setStringValue:@""];
  [alert setAccessoryView:input];
  NSInteger button = [alert runModal];
  if (button == NSAlertDefaultReturn)
  {
    [input validateEditing];
    pid_t targetPid = [input intValue];
    NSLog(@"Attach to process %d", targetPid);
    mach_vm_address_t mainAddress = 0;
    if (find_main_binary(targetPid, &mainAddress))
    {
      NSLog(@"Failed to find main binary address!");
      return;
    }
    uint64_t aslr_slide = 0;
    uint64_t imagesize = 0;
    if ( (imagesize = get_image_size(mainAddress, targetPid, &aslr_slide)) == 0 )
    {
      NSLog(@"[ERROR] Got image file size equal to 0!");
      return;
    }
    /* allocate the buffer to contain the memory dump */
    uint8_t *readbuffer = (uint8_t*)malloc(imagesize);
    if (readbuffer == NULL)
    {
      NSLog(@"Can't allocate mem for dumping target!");
      return;
    }
    /* and finally read the sections and dump their contents to the buffer */
    if (dump_binary(mainAddress, targetPid, readbuffer, aslr_slide))
    {
      NSLog(@"Main binary memory dump failed!");
      free(readbuffer);
      return;
    }
    /* dump buffer contents to temporary file to use the NSDocument model */
    const char *tmp = [[MVDocument temporaryDirectory] UTF8String];
    char *dumpFilePath = (char*)malloc(strlen(tmp)+1);
    if (dumpFilePath == NULL)
    {
      NSLog(@"Can't allocate mem for temp filename path!");
      free(readbuffer);
      return;
    }
    strcpy(dumpFilePath, tmp);
    int outputFile = 0;
    if ( (outputFile = mkstemp(dumpFilePath)) == -1 )
    {
      NSLog(@"mkstemp failed!");
      free(dumpFilePath);
      free(readbuffer);
      return;
    }
    
    if (write(outputFile, readbuffer, imagesize) == -1)
    {
      NSLog(@"[ERROR] Write error at %s occurred!\n", dumpFilePath);
      free(dumpFilePath);
      free(readbuffer);
      return;
    }
    NSLog(@"\n[OK] Full binary dumped to %s!\n\n", dumpFilePath);
    close(outputFile);
    
    [self application:NSApp openFile:[NSString stringWithCString:dumpFilePath encoding:NSUTF8StringEncoding]];
    /* remove temporary dump file, not required anymore */
    NSFileManager * fileManager = [NSFileManager defaultManager];
    [fileManager removeItemAtPath:[NSString stringWithCString:dumpFilePath encoding:NSUTF8StringEncoding] error:NULL];
    free(dumpFilePath);
    free(readbuffer);
  }
  else if (button == NSAlertAlternateReturn)
  {
    /* nothing to do here */
  }
  else
  {
    NSAssert1(NO, @"Invalid input dialog button %ld", button);
  }
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
//  if([[NSUserDefaults standardUserDefaults] objectForKey: @"UseLLVMDisassembler"] != nil)
//    qflag = [[NSUserDefaults standardUserDefaults] boolForKey:@"UseLLVMDisassembler"];

  
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

  /* default is to not open a file dialogue */
  if ([[NSUserDefaults standardUserDefaults] objectForKey:@"OpenAtLaunch"] != nil)
  {
    if ([[NSUserDefaults standardUserDefaults] boolForKey:@"OpenAtLaunch"] == YES)
    {
      // if there is no document yet, then pop up an open file dialogue
      // XXX: irrelevant check, no?
      if ([[[NSDocumentController sharedDocumentController] documents] count] == 0)
      {
        [self openDocument:nil];
      }
    }
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


