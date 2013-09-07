#ifndef _STUFF_LLVM_H_
#define _STUFF_LLVM_H_

#include "llvm-c/Disassembler.h"

__private_extern__ LLVMDisasmContextRef llvm_create_disasm(
    const char *TripleName,
    void *DisInfo,
    int TagType,
    LLVMOpInfoCallback GetOpInfo,
    LLVMSymbolLookupCallback SymbolLookUp);

__private_extern__ void llvm_disasm_dispose(
    LLVMDisasmContextRef DC);

__private_extern__ size_t llvm_disasm_instruction(
    LLVMDisasmContextRef DC,
    uint8_t *Bytes,
    uint64_t BytesSize,
    uint64_t Pc,
    char *OutString,
    size_t OutStringSize);

#endif /* _STUFF_LLVM_H_ */
