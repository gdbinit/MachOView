/*
 *  DataController.h
 *  MachOView
 *
 *  Created by psaghelyi on 15/06/2010.
 *
 */

#define OFFSET_COLUMN       0
#define DATA_COLUMN         1   // use this with details
#define DESCRIPTION_COLUMN  2   // use this with details
#define VALUE_COLUMN        3

#define DATA_LO_COLUMN      1   // use this with no details
#define DATA_HI_COLUMN      2   // use this with no details

extern NSString * const MVUnderlineAttributeName;
extern NSString * const MVCellColorAttributeName;
extern NSString * const MVTextColorAttributeName;
extern NSString * const MVMetaDataAttributeName;

extern NSString * const MVLayoutUserInfoKey;
extern NSString * const MVNodeUserInfoKey;
extern NSString * const MVStatusUserInfoKey;

extern NSString * const MVDataTreeWillChangeNotification;
extern NSString * const MVDataTreeDidChangeNotification;
extern NSString * const MVDataTreeChangedNotification;
extern NSString * const MVDataTableChangedNotification;
extern NSString * const MVThreadStateChangedNotification;

extern NSString * const MVStatusTaskStarted;
extern NSString * const MVStatusTaskTerminated;

struct MVNodeSaver;

@protocol MVSerializing <NSObject>
- (void)loadFromFile:(FILE *)pFile;
- (void)saveToFile:(FILE *)pFile;
- (void)clear;
@end

//----------------------------------------------------------------------------
@interface MVColoumns : NSObject
{
  NSString *            offsetStr;
  NSString *            dataStr;
  NSString *            descriptionStr;
  NSString *            valueStr;
}

@property (nonatomic)   NSString * offsetStr;
@property (nonatomic)   NSString * dataStr;
@property (nonatomic)   NSString * descriptionStr;
@property (nonatomic)   NSString * valueStr;

+(MVColoumns *) coloumnsWithData:(NSString *)col0 :(NSString *)col1 :(NSString *)col2 :(NSString *)col3;

@end

//----------------------------------------------------------------------------
@interface MVRow : NSObject <MVSerializing>
{
  MVColoumns *          coloumns;
  NSDictionary *        attributes;
  uint32_t              offset;           // for sorting if necessary
  uint32_t              coloumnsOffset;   // offset of coloumns
  uint32_t              attributesOffset; // offset of attribues
  BOOL                  deleted;
  BOOL                  dirty;            // eg. attributes has changed
}

@property (nonatomic)   NSDictionary * attributes;
@property (nonatomic)   MVColoumns * coloumns;
@property (nonatomic)   uint32_t offset;
@property (nonatomic)   BOOL deleted;
@property (nonatomic)   BOOL dirty;

-(NSString *)coloumnAtIndex:(NSUInteger)index;

@end

@class MVArchiver;

//----------------------------------------------------------------------------
@interface MVTable : NSObject
{
  NSMutableArray *      rows;         // array of MVRow * (host of all the rows)
  NSMutableArray *      displayRows;  // array of MVRow * (rows filtered by search criteria)
  MVArchiver *          __weak archiver;
  FILE *                swapFile;
  NSLock *              tableLock;
}

@property (nonatomic)   FILE * swapFile;

- (NSUInteger)          rowCountToDisplay;
- (MVRow *)             getRowToDisplay:(NSUInteger)rowIndex;

- (void)                popRow;
- (void)                appendRow:(id)col0 :(id)col1 :(id)col2 :(id)col3;
- (void)                insertRowWithOffset:(uint32_t)offset :(id)col0 :(id)col1 :(id)col2 :(id)col3;
- (void)                updateCellContentTo:(id)object atRow:(NSUInteger)rowIndex andCol:(NSUInteger)colIndex;

- (NSUInteger)          rowCount;
- (void)                setAttributes:(NSString *)firstArg, ... NS_REQUIRES_NIL_TERMINATION;
- (void)                setAttributesForRowIndex:(NSUInteger)index :(NSString *)firstArg, ... NS_REQUIRES_NIL_TERMINATION;
- (void)                setAttributesFromRowIndex:(NSUInteger)index :(NSString *)firstArg, ... NS_REQUIRES_NIL_TERMINATION;

@end

//----------------------------------------------------------------------------
@interface MVNode : NSObject <MVSerializing>
{
  NSString *            caption;
  MVNode *              __weak parent;
  NSMutableArray *      children;
  NSRange               dataRange;
  MVTable *             details;
  NSMutableDictionary * userInfo;
  uint32_t              detailsOffset;
}

@property (nonatomic)                   NSString *            caption;
@property (nonatomic,weak)      MVNode *              parent;
@property (nonatomic)                   NSRange               dataRange;
@property (nonatomic)                   MVTable *             details;
@property (nonatomic)                   NSMutableDictionary * userInfo;
@property (nonatomic)                   uint32_t              detailsOffset;

- (NSUInteger)          numberOfChildren;
- (MVNode *)            childAtIndex:(NSUInteger)n;
- (MVNode *)            insertChild:(NSString *)_caption location:(uint32_t)location length:(uint32_t)length;
- (MVNode *)            insertChildWithDetails:(NSString *)_caption location:(uint32_t)location length:(uint32_t)length saver:(MVNodeSaver &)saver;
- (MVNode *)            findNodeByUserInfo:(NSDictionary *)uinfo;
- (void)                openDetails;  // open swap file for reading details on demand
- (void)                closeDetails; // close swap file
- (void)                sortDetails;
- (void)                filterDetails:(NSString *)filter;
- (void)                loadFromFile:(FILE *)pFile;
- (void)                saveToFile:(FILE *)pFile;

@end

//----------------------------------------------------------------------------
@interface MVDataController : NSObject
{
  NSString *            fileName;         // path to the binary handled by this data controller
  NSMutableData *       fileData;         // content of the binary 
  NSMutableData *       realData;         // patched content by relocs and bindings
  NSMutableArray *      layouts;
  MVNode *              rootNode;
  MVNode *              __weak selectedNode;
  NSLock *              treeLock;         // semaphore for the node tree
}

@property (nonatomic)                   NSString *      fileName;
@property (nonatomic)                   NSMutableData * fileData;
@property (nonatomic)                   NSMutableData * realData;
@property (nonatomic,readonly)          NSArray *       layouts;
@property (nonatomic,readonly)          MVNode *        rootNode;
@property (nonatomic,weak)              MVNode *        selectedNode;
@property (nonatomic,readonly)          NSLock *        treeLock;

-(NSString *)           getMachine:(cpu_type_t)cputype;
-(NSString *)           getARMCpu:(cpu_subtype_t)cpusubtype;

- (void)                createLayouts:(MVNode *)parent location:(uint32_t)location length:(uint32_t)length;
- (void)                updateTreeView: (MVNode *)node;
- (void)                updateTableView;
- (void)                updateStatus: (NSString *)status;

@end

//----------------------------------------------------------------------------
@interface MVArchiver : NSObject
{
  NSString *            swapPath;
  NSMutableArray *      objectsToSave; // conforms MVSerializing
  NSThread *            saverThread;
  NSLock *              saverLock;
}

@property (nonatomic,readonly)  NSString * swapPath;

+(MVArchiver *) archiverWithPath:(NSString *)path;
-(void) addObjectToSave:(id)object;
-(void) suspend;
-(void) resume;
-(void) halt;

@end

//----------------------------------------------------------------------------
struct MVNodeSaver
{
  MVNodeSaver();
  ~MVNodeSaver();
  
  void setNode(MVNode * node) { m_node = node; }
  
private:
  MVNodeSaver(MVNodeSaver const &);
  MVNodeSaver & operator=(MVNodeSaver const &);
  
  MVNode * __weak m_node;
};


