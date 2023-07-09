//
//  CodeSignature.m
//  MachOView
//
//  Created by ByteDance on 2023/7/9.
//

/* code signing attributes of a process */
#define    CS_VALID        0x0000001    /* dynamically valid */
#define CS_ADHOC        0x0000002    /* ad hoc signed */
#define CS_GET_TASK_ALLOW    0x0000004    /* has get-task-allow entitlement */
#define CS_INSTALLER        0x0000008    /* has installer entitlement */

#define    CS_HARD            0x0000100    /* don't load invalid pages */
#define    CS_KILL            0x0000200    /* kill process if it becomes invalid */
#define CS_CHECK_EXPIRATION    0x0000400    /* force expiration checking */
#define CS_RESTRICT        0x0000800    /* tell dyld to treat restricted */
#define CS_ENFORCEMENT        0x0001000    /* require enforcement */
#define CS_REQUIRE_LV        0x0002000    /* require library validation */
#define CS_ENTITLEMENTS_VALIDATED    0x0004000

#define    CS_ALLOWED_MACHO    0x00ffffe

#define CS_EXEC_SET_HARD    0x0100000    /* set CS_HARD on any exec'ed process */
#define CS_EXEC_SET_KILL    0x0200000    /* set CS_KILL on any exec'ed process */
#define CS_EXEC_SET_ENFORCEMENT    0x0400000    /* set CS_ENFORCEMENT on any exec'ed process */
#define CS_EXEC_SET_INSTALLER    0x0800000    /* set CS_INSTALLER on any exec'ed process */

#define CS_KILLED        0x1000000    /* was killed by kernel for invalidity */
#define CS_DYLD_PLATFORM    0x2000000    /* dyld used to load this is a platform binary */
#define CS_PLATFORM_BINARY    0x4000000    /* this is a platform binary */
#define CS_PLATFORM_PATH    0x8000000    /* platform binary by the fact of path (osx only) */

#define CS_ENTITLEMENT_FLAGS    (CS_GET_TASK_ALLOW | CS_INSTALLER)

/* MAC flags used by F_ADDFILESIGS_* */
#define MAC_VNODE_CHECK_DYLD_SIM 0x1   /* tells the MAC framework that dyld-sim is being loaded */

/* csops  operations */
#define    CS_OPS_STATUS        0    /* return status */
#define    CS_OPS_MARKINVALID    1    /* invalidate process */
#define    CS_OPS_MARKHARD        2    /* set HARD flag */
#define    CS_OPS_MARKKILL        3    /* set KILL flag (sticky) */
#ifdef KERNEL_PRIVATE
/* CS_OPS_PIDPATH        4    */
#endif
#define    CS_OPS_CDHASH        5    /* get code directory hash */
#define CS_OPS_PIDOFFSET    6    /* get offset of active Mach-o slice */
#define CS_OPS_ENTITLEMENTS_BLOB 7    /* get entitlements blob */
#define CS_OPS_MARKRESTRICT    8    /* set RESTRICT flag (sticky) */
#define CS_OPS_SET_STATUS    9    /* set codesign flags */
#define CS_OPS_BLOB        10    /* get codesign blob */
#define CS_OPS_IDENTITY        11    /* get codesign identity */

/*
 * Magic numbers used by Code Signing
 */
enum {
    CSMAGIC_REQUIREMENT = 0xfade0c00,        /* single Requirement blob */
    CSMAGIC_REQUIREMENTS = 0xfade0c01,        /* Requirements vector (internal requirements) */
    CSMAGIC_CODEDIRECTORY = 0xfade0c02,        /* CodeDirectory blob */
    CSMAGIC_EMBEDDED_SIGNATURE = 0xfade0cc0, /* embedded form of signature data */
    CSMAGIC_EMBEDDED_SIGNATURE_OLD = 0xfade0b02,    /* XXX */
    CSMAGIC_EMBEDDED_ENTITLEMENTS = 0xfade7171,    /* embedded entitlements */
    CSMAGIC_DETACHED_SIGNATURE = 0xfade0cc1, /* multi-arch collection of embedded signatures */
    CSMAGIC_BLOBWRAPPER = 0xfade0b01,    /* CMS Signature, among other things */
    
    CS_SUPPORTSSCATTER = 0x20100,
    CS_SUPPORTSTEAMID = 0x20200,

    CSSLOT_CODEDIRECTORY = 0,                /* slot index for CodeDirectory */
    CSSLOT_INFOSLOT = 1,
    CSSLOT_REQUIREMENTS = 2,
    CSSLOT_RESOURCEDIR = 3,
    CSSLOT_APPLICATION = 4,
    CSSLOT_ENTITLEMENTS = 5,
    CSSLOT_ENTITLEMENTS_DER = 7,
    CSSLOT_ALTERNATE_CODEDIRECTORIES = 0x1000,
    CSSLOT_SIGNATURESLOT = 0x10000,            /* CMS Signature */

    CSTYPE_INDEX_REQUIREMENTS = 0x00000002,        /* compat with amfi */
    CSTYPE_INDEX_ENTITLEMENTS = 0x00000005,        /* compat with amfi */

    CS_HASHTYPE_SHA1 = 1,
    CS_HASHTYPE_SHA256 = 2,
    CS_HASHTYPE_SHA256_TRUNCATED = 3,

    CS_SHA1_LEN = 20,
    CS_SHA256_TRUNCATED_LEN = 20,

    CS_CDHASH_LEN = 20,
    CS_HASH_MAX_SIZE = 32, /* max size of the hash we'll support */
};


#define KERNEL_HAVE_CS_CODEDIRECTORY 1
#define KERNEL_CS_CODEDIRECTORY_HAVE_PLATFORM 1

/*
 * C form of a CodeDirectory.
 */
typedef struct __CodeDirectory {
    uint32_t magic;                    /* magic number (CSMAGIC_CODEDIRECTORY) */
    uint32_t length;                /* total length of CodeDirectory blob */
    uint32_t version;                /* compatibility version */
    uint32_t flags;                    /* setup and mode flags */
    uint32_t hashOffset;            /* offset of hash slot element at index zero */
    uint32_t identOffset;            /* offset of identifier string */
    uint32_t nSpecialSlots;            /* number of special hash slots */
    uint32_t nCodeSlots;            /* number of ordinary (code) hash slots */
    uint32_t codeLimit;                /* limit to main image signature range */
    uint8_t hashSize;                /* size of each hash in bytes */
    uint8_t hashType;                /* type of hash (cdHashType* constants) */
    uint8_t platform;                /* platform identifier; zero if not platform binary */
    uint8_t    pageSize;                /* log2(page size in bytes); 0 => infinite */
    uint32_t spare2;                /* unused (must be zero) */
    /* Version 0x20100 */
    uint32_t scatterOffset;                /* offset of optional scatter vector */
    /* Version 0x20200 */
    uint32_t teamOffset;                /* offset of optional team identifier */
    /* followed by dynamic content as located by offset fields above */
} CS_CodeDirectory;

/*
 * Structure of an embedded-signature SuperBlob
 */

typedef struct __BlobIndex {
    uint32_t type;                    /* type of entry */
    uint32_t offset;                /* offset of entry */
} CS_BlobIndex;


typedef struct __SC_SuperBlob {
    uint32_t magic;                    /* magic number */
    uint32_t length;                /* total length of SuperBlob */
    uint32_t count;                    /* number of index entries following */
    CS_BlobIndex index[];            /* (count) entries */
    /* followed by Blobs in no particular order as indicated by offsets in index */
} CS_SuperBlob;

#define KERNEL_HAVE_CS_GENERICBLOB 1
// CSSLOT_ENTITLEMENTS
typedef struct __SC_GenericBlob {
    uint32_t magic;                /* magic number */
    uint32_t length;            /* total length of blob */
    char data[];
} CS_GenericBlob;

typedef struct __SC_Scatter {
    uint32_t count;            // number of pages; zero for sentinel (only)
    uint32_t base;            // first page number
    uint64_t targetOffset;        // offset in target
    uint64_t spare;            // reserved
} SC_Scatter;

NSString* parse_magic(uint32_t magic);
NSString* parse_type(uint32_t type);
uint32_t swap32(uint32_t num);
