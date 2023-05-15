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
  uint64_t              imageOffset;  // absolute physical offset of the image in binary
  uint64_t              imageSize;    // size of the image corresponds to this layout
  NSThread *            backgroundThread;
  MVArchiver *          archiver;
}

@property(nonatomic,weak,readonly)  MVDataController * dataController;
@property(nonatomic,readonly) NSThread * backgroundThread;
@property(nonatomic,readonly) MVArchiver * archiver;

- (instancetype)        init NS_UNAVAILABLE;
- (instancetype)        initWithDataController:(MVDataController *)dc rootNode:(MVNode *)node NS_DESIGNATED_INITIALIZER;
- (void const *)        imageAt:(uint64_t)location NS_RETURNS_INNER_POINTER;
- (void)                printException:(NSException *)exception caption:(NSString *)caption;
- (BOOL)                is64bit;
- (void)                doMainTasks;
- (void)                doBackgroundTasks;
- (NSString *)          convertToRVA: (NSString *)offsetStr;
- (MVNode *)            findNodeByUserInfo:(NSDictionary *)userInfo;

- (MVNode *)            createDataNode:(MVNode *)parent
                               caption:(NSString *)caption
                              location:(uint64_t)location
                                length:(uint64_t)length;

@end
