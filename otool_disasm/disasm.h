/*
 * Copyright © 2009 Apple Inc. All rights reserved.
 *
 * @APPLE_LICENSE_HEADER_START@
 * 
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions are met:
 * 
 * 1.  Redistributions of source code must retain the above copyright notice,
 * this list of conditions and the following disclaimer. 
 * 2.  Redistributions in binary form must reproduce the above copyright notice,
 * this list of conditions and the following disclaimer in the documentation
 * and/or other materials provided with the distribution. 
 * 3.  Neither the name of Apple Inc. ("Apple") nor the names of its
 * contributors may be used to endorse or promote products derived from this
 * software without specific prior written permission. 
 * 
 * THIS SOFTWARE IS PROVIDED BY APPLE AND ITS CONTRIBUTORS "AS IS" AND ANY
 * EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
 * WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
 * DISCLAIMED. IN NO EVENT SHALL APPLE OR ITS CONTRIBUTORS BE LIABLE FOR ANY
 * DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
 * (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
 * LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
 * ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 * (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF
 * THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 *
 * @APPLE_LICENSE_HEADER_END@
 */


#ifndef _DISASM_H_
#define _DISASM_H_

#include "llvm-c/Disassembler.h"
//#include "stuff/symbol.h"

enum byte_sex 
{
  UNKNOWN_BYTE_SEX,
  BIG_ENDIAN_BYTE_SEX,
  LITTLE_ENDIAN_BYTE_SEX
};

typedef signed char BOOL;
//#define TRUE    ((BOOL)1)
//#define FALSE   ((BOOL)0)

// the subset of flag definitions from otool.h which we use for disassembling
extern BOOL vflag; /* print verbosely (symbolically) when possible */
extern BOOL Vflag; /* print dissassembled operands verbosely */
extern BOOL qflag; /* use 'C' Public llvm-mc disassembler */
extern BOOL eflag; /* print enhanced disassembly */
extern BOOL gflag; /* group the disassembly */
extern BOOL nflag; /* use intel disassembly syntax */

extern BOOL in_thumb;

struct inst {
  uint64_t address;
  char *label;
  BOOL needs_tmp_label;
  char *tmp_label;
  BOOL print;
  BOOL has_raw_target_address;
  uint64_t raw_target_address;
};

extern "C" {
  
int
sym_compare(
            struct symbol *sym1,
            struct symbol *sym2
            );
  
int
rel_compare(
            struct relocation_info *rel1,
            struct relocation_info *rel2
            );

LLVMDisasmContextRef create_i386_llvm_disassembler(void);
LLVMDisasmContextRef create_x86_64_llvm_disassembler(void);
LLVMDisasmContextRef create_arm_llvm_disassembler(cpu_subtype_t cpusubtype);
LLVMDisasmContextRef create_thumb_llvm_disassembler(cpu_subtype_t cpusubtype);

void delete_i386_llvm_disassembler(LLVMDisasmContextRef dc);
void delete_x86_64_llvm_disassembler(LLVMDisasmContextRef dc);
void delete_arm_llvm_disassembler(LLVMDisasmContextRef dc);
void delete_thumb_llvm_disassembler(LLVMDisasmContextRef dc);

int llvm_disasm_set_options(LLVMDisasmContextRef DC, uint64_t Options);

const char * guess_symbol(
                                     const uint64_t value,
                                     const struct symbol *sorted_symbols,
                                     const uint32_t nsorted_symbols,
                          const BOOL verbose = true);

uint32_t i386_disassemble(
                                     char *sect,
                                     uint32_t left,
                                     uint64_t addr,
                                     uint64_t sect_addr,
                                     enum byte_sex object_byte_sex,
                                     struct relocation_info *sorted_relocs,
                                     uint32_t nsorted_relocs,
                                     struct nlist *symbols,
                                     struct nlist_64 *symbols64,
                                     uint32_t nsymbols,
                                     struct symbol *sorted_symbols,
                                     uint32_t nsorted_symbols,
                                     char *strings,
                                     uint32_t strings_size,
                                     uint32_t *indirect_symbols,
                                     uint32_t nindirect_symbols,
                                     cpu_type_t cputype,
                                     struct load_command *load_commands,
                                     uint32_t ncmds,
                                     uint32_t sizeofcmds,
                          BOOL verbose,
                          BOOL llvm_mc,
                                     LLVMDisasmContextRef i386_dc,
                                     LLVMDisasmContextRef x86_64_dc,
                                     char *object_addr,
                          uint32_t object_size,
                          struct inst *inst,
                          struct inst *insts,
                          uint32_t ninsts,
                          uint32_t filetype);


uint32_t arm_disassemble(
                                    char *sect,
                                    uint32_t left,
                                    uint32_t addr,
                                    uint32_t sect_addr,
                                    enum byte_sex object_byte_sex,
                                    struct relocation_info *sorted_relocs,
                                    uint32_t nsorted_relocs,
                                    struct nlist *symbols,
                                    uint32_t nsymbols,
                                    struct symbol *sorted_symbols,
                                    uint32_t nsorted_symbols,
                                    char *strings,
                                    uint32_t strings_size,
                                    uint32_t *indirect_symbols,
                                    uint32_t nindirect_symbols,
                                    struct load_command *load_commands,
                                    uint32_t ncmds,
                                    uint32_t sizeofcmds,
                                    cpu_subtype_t cpu_subtype,
                         BOOL verbose,
                                    LLVMDisasmContextRef arm_dc,
                                    LLVMDisasmContextRef thumb_dc,
                                    char *object_addr,
                                    uint32_t object_size,
                                    struct data_in_code_entry *dices,
                         uint32_t ndices,
                         uint64_t seg_addr,
                         struct inst *inst,
                         struct inst *insts,
                         uint32_t ninsts);

} // extern "C"

#endif
