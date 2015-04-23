/*
 *  Layout.h
 *  MachOView
 *
 *  Created by psaghelyi on 18/03/2011.
 *
 */


#define MATCH_STRUCT(obj,location) \
  struct obj const * obj = (struct obj *)[self imageAt:(location)]; \
  if (!obj) [NSException raise:@"null exception" format:@#obj " is null"];

@class MVDataController;
@class MVArchiver;
@class MVNode;


@interface MVLayout : NSObject 
{
  MVNode *              __weak rootNode;
  MVDataController *    __weak dataController;
  uint32_t              imageOffset;  // absolute physical offset of the image in binary
  uint32_t              imageSize;    // size of the image corresponds to this layout
  NSThread *            backgroundThread;
  MVArchiver *          archiver;
}

@property(nonatomic,weak,readonly)  MVDataController * dataController;
@property(nonatomic,readonly) NSThread * backgroundThread;
@property(nonatomic,readonly) MVArchiver * archiver;

- (id)                  initWithDataController:(MVDataController *)dc rootNode:(MVNode *)node;
- (void const *)        imageAt:(uint32_t)location;
- (void)                printException:(NSException *)exception caption:(NSString *)caption;
- (BOOL)                is64bit;
- (void)                doMainTasks;
- (void)                doBackgroundTasks;
- (NSString *)          convertToRVA: (NSString *)offsetStr;
- (MVNode *)            findNodeByUserInfo:(NSDictionary *)userInfo;

- (MVNode *)            createDataNode:(MVNode *)parent
                               caption:(NSString *)caption
                              location:(uint32_t)location
                                length:(uint32_t)length;

@end
