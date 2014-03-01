#include <stdio.h>
#include <stdlib.h>
#include <libc.h>
#include <sys/file.h>
#include <dlfcn.h>
#include "llvm-c/Disassembler.h"
#include "stuff/llvm.h"
#include "stuff/allocate.h"
#include <mach-o/dyld.h>

/*
 * The disassembler API is currently exported from libLTO.dylib.  Eventually we
 * plan to include it (along with the current libLTO APIs) in a generic
 * libLLVM.dylib.
 */
#define LIB_LLVM "libLTO.dylib"

static int tried_to_load_llvm = 0;
static void *llvm_handle = NULL;
static void (*initialize)(void) = NULL;
static LLVMDisasmContextRef (*create)(const char *, void *, int,
	LLVMOpInfoCallback, LLVMSymbolLookupCallback) = NULL;
static LLVMDisasmContextRef (*createCPU)(const char *, const char *,void *, int,
	LLVMOpInfoCallback, LLVMSymbolLookupCallback) = NULL;
static void (*dispose)(LLVMDisasmContextRef) = NULL;
static size_t (*disasm)(LLVMDisasmContextRef, uint8_t *, uint64_t, uint64_t,
	char *, size_t) = NULL;
static int (*options)(LLVMDisasmContextRef, uint64_t) = NULL;

/*
 * Wrapper to dynamically load LIB_LLVM and call LLVMCreateDisasm().
 */
__private_extern__
LLVMDisasmContextRef
llvm_create_disasm(
const char *TripleName,
const char *CPU,
void *DisInfo,
int TagType,
LLVMOpInfoCallback GetOpInfo,
LLVMSymbolLookupCallback SymbolLookUp)
{
   uint32_t bufsize;
   char *p, *prefix, *llvm_path, buf[MAXPATHLEN], resolved_name[PATH_MAX];
   int i;
   LLVMDisasmContextRef DC;

	if(tried_to_load_llvm == 0){
	    tried_to_load_llvm = 1;
	    /*
	     * Construct the prefix to this executable assuming it is in a bin
	     * directory relative to a lib directory of the matching lto library
	     * and first try to load that.  If not then fall back to trying
	     * "/Applications/Xcode.app/Contents/Developer/Toolchains/
	     * XcodeDefault.xctoolchain/usr/lib/" LIB_LLVM.
	     */
	    bufsize = MAXPATHLEN;
	    p = buf;
	    i = _NSGetExecutablePath(p, &bufsize);
	    if(i == -1){
		p = allocate(bufsize);
		_NSGetExecutablePath(p, &bufsize);
	    }
	    prefix = realpath(p, resolved_name);
	    p = rindex(prefix, '/');
	    if(p != NULL)
		p[1] = '\0';
	    llvm_path = makestr(prefix, "../lib/" LIB_LLVM, NULL);

	    llvm_handle = dlopen(llvm_path, RTLD_NOW);
	    if(llvm_handle == NULL){
		free(llvm_path);
		llvm_path = NULL;
		llvm_handle = dlopen("/Applications/Xcode.app/Contents/"
				     "Developer/Toolchains/XcodeDefault."
				     "xctoolchain/usr/lib/" LIB_LLVM,
				    RTLD_NOW);
	    }
	    if(llvm_handle == NULL)
		return(0);

	    create = dlsym(llvm_handle, "LLVMCreateDisasm");
	    dispose = dlsym(llvm_handle, "LLVMDisasmDispose");
	    disasm = dlsym(llvm_handle, "LLVMDisasmInstruction");

	    /* Note we allow these to not be defined */
	    options = dlsym(llvm_handle, "LLVMSetDisasmOptions");
	    createCPU = dlsym(llvm_handle, "LLVMCreateDisasmCPU");

	    if(create == NULL ||
	       dispose == NULL ||
	       disasm == NULL){

		dlclose(llvm_handle);
		if(llvm_path != NULL)
		    free(llvm_path);
		llvm_handle = NULL;
		create = NULL;
		createCPU = NULL;
		dispose = NULL;
		disasm = NULL;
		options = NULL;
		return(NULL);
	    }
	}
	if(llvm_handle == NULL)
	    return(NULL);

	/*
	 * Note this was added after the interface was defined, so it may
	 * be undefined.  But if not we must call it first.
	 */
	initialize = dlsym(llvm_handle, "lto_initialize_disassembler");
	if(initialize != NULL)
	    initialize();

	if(*CPU != '\0' && createCPU != NULL)
	    DC = createCPU(TripleName, CPU, DisInfo, TagType, GetOpInfo,
			   SymbolLookUp);
	else
	DC = create(TripleName, DisInfo, TagType, GetOpInfo, SymbolLookUp);
	return(DC);
}

/*
 * Wrapper to call LLVMDisasmDispose().
 */
__private_extern__
void
llvm_disasm_dispose(
LLVMDisasmContextRef DC)
{
	if(dispose != NULL)
	    dispose(DC);
}

/*
 * Wrapper to call LLVMDisasmInstruction().
 */
__private_extern__
size_t
llvm_disasm_instruction(
LLVMDisasmContextRef DC,
uint8_t *Bytes,
uint64_t BytesSize,
uint64_t Pc,
char *OutString,
size_t OutStringSize)
{

	if(disasm == NULL)
	    return(0);
	return(disasm(DC, Bytes, BytesSize, Pc, OutString, OutStringSize));
}

/*
 * Wrapper to call LLVMSetDisasmOptions().
 */
__private_extern__
int
llvm_disasm_set_options(
LLVMDisasmContextRef DC,
uint64_t Options)
{

	if(options == NULL)
	    return(0);
	return(options(DC, Options));
}
