/*
 *  Layout.h
 *  MachOView
 *
 *  Created by psaghelyi on 18/03/2011.
 *
 */


#define MATCH_STRUCT(obj,location) \
struct obj const * obj = (struct obj const *)((uint8_t *)[dataController.realData bytes] + (location));


@class MVDataController;
@class MVArchiver;
@class MVNode;


@interface MVLayout : NSObject 
{
  MVNode *              rootNode;
  MVDataController *    __unsafe_unretained dataController;
  uint32_t              imageOffset;      // absolute physical offset in binary
  NSThread *            backgroundThread;
  MVArchiver *          archiver;
}

@property(nonatomic,unsafe_unretained,readonly) MVDataController * dataController;
@property(nonatomic,readonly) NSThread * backgroundThread;
@property(nonatomic,readonly) MVArchiver * archiver;

- (id)                  initWithDataController:(MVDataController *)dc rootNode:(MVNode *)node;
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
