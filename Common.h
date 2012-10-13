/*
 *  Common.h
 *  MachOView
 *
 *  Created by Peter Saghelyi on 10/09/2011.
 *
 */


//#define MV_NO_MULTITHREAD
//#define MV_NO_ARCHIVER
//#define MV_STATISTICS

extern NSCondition * pipeCondition;
extern int32_t numIOThread;
extern int64_t nrow_total;  // number of rows (loaded and empty)
extern int64_t nrow_loaded; // number of loaded rows

#define NSSTRING(C_STR) [NSString stringWithCString: (char *)(C_STR) encoding: [NSString defaultCStringEncoding]]
#define CSTRING(NS_STR) [(NS_STR) cStringUsingEncoding: [NSString defaultCStringEncoding]]

// Lion includes don't have these
#define CPU_SUBTYPE_ARM_V7F             ((cpu_subtype_t) 10) /* Cortex A9 */
#define CPU_SUBTYPE_ARM_V7K             ((cpu_subtype_t) 12) /* Kirkwood40 */
// Lion & Mountain Lion includes don't have these, only the iOS 6.0 SDK
#define CPU_SUBTYPE_ARM_V7S             ((cpu_subtype_t) 11) /* Swift */
#define CPUFAMILY_ARM_12            0xbd1b0ae9
#define CPUFAMILY_ARM_SWIFT 		0x1e2d6381

