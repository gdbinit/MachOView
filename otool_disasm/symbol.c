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

#include <stdlib.h>
#include <stddef.h>
#include <string.h>
#include <ctype.h>

#include "stuff/bytesex.h"
#include "stuff/symbol.h"


/*
 * Function for qsort for comparing symbols.
 */
int
sym_compare(
            struct symbol *sym1,
            struct symbol *sym2)
{
	if(sym1->n_value == sym2->n_value)
    return(0);
	if(sym1->n_value < sym2->n_value)
    return(-1);
	else
    return(1);
}

/*
 * Function for qsort for comparing relocation entries.
 */
int
rel_compare(
            struct relocation_info *rel1,
            struct relocation_info *rel2)
{
  struct scattered_relocation_info *srel;
  uint32_t r_address1, r_address2;
  
	if((rel1->r_address & R_SCATTERED) != 0){
    srel = (struct scattered_relocation_info *)rel1;
    r_address1 = srel->r_address;
	}
	else
    r_address1 = rel1->r_address;
	if((rel2->r_address & R_SCATTERED) != 0){
    srel = (struct scattered_relocation_info *)rel2;
    r_address2 = srel->r_address;
	}
	else
    r_address2 = rel2->r_address;
  
	if(r_address1 == r_address2)
    return(0);
	if(r_address1 < r_address2)
    return(-1);
	else
    return(1);
}


/*
 * guess_symbol() guesses the name for a symbol based on the specified value.
 * It returns the name of symbol or NULL.  It only returns a symbol name if
 *  a symbol with that exact value exists.
 */
const char *
guess_symbol(
             const uint64_t value,	/* the value of this symbol (in) */
             const struct symbol *sorted_symbols,
             const uint32_t nsorted_symbols,
             const enum bool verbose)
{
  int32_t high, low, mid;
  
	if(verbose == FALSE)
    return(NULL);
  
	low = 0;
	high = nsorted_symbols - 1;
	mid = (high - low) / 2;
	while(high >= low){
    if(sorted_symbols[mid].n_value == value){
      return(sorted_symbols[mid].name);
    }
    if(sorted_symbols[mid].n_value > value){
      high = mid - 1;
      mid = (high + low) / 2;
    }
    else{
      low = mid + 1;
      mid = (high + low) / 2;
    }
	}
	return(NULL);
}


/*
 * guess_indirect_symbol() returns the name of the indirect symbol for the
 * value passed in or NULL.
 */
const char *
guess_indirect_symbol(
                      const uint64_t value,	/* the value of this symbol (in) */
                      const uint32_t ncmds,
                      const uint32_t sizeofcmds,
                      const struct load_command *load_commands,
                      const enum byte_sex load_commands_byte_sex,
                      const uint32_t *indirect_symbols,
                      const uint32_t nindirect_symbols,
                      const struct nlist *symbols,
                      const struct nlist_64 *symbols64,
                      const uint32_t nsymbols,
                      const char *strings,
                      const uint32_t strings_size)
{
  enum byte_sex host_byte_sex;
  enum bool swapped;
  uint32_t i, j, section_type, index, stride;
  const struct load_command *lc;
  struct load_command l;
  struct segment_command sg;
  struct section s;
  struct segment_command_64 sg64;
  struct section_64 s64;
  char *p;
  uint64_t big_load_end;
  
	host_byte_sex = get_host_byte_sex();
	swapped = host_byte_sex != load_commands_byte_sex;
  
	lc = load_commands;
	big_load_end = 0;
	for(i = 0 ; i < ncmds; i++){
    memcpy((char *)&l, (char *)lc, sizeof(struct load_command));
    if(swapped)
      swap_load_command(&l, host_byte_sex);
    if(l.cmdsize % sizeof(int32_t) != 0)
      return(NULL);
    big_load_end += l.cmdsize;
    if(big_load_end > sizeofcmds)
      return(NULL);
    switch(l.cmd){
	    case LC_SEGMENT:
        memcpy((char *)&sg, (char *)lc, sizeof(struct segment_command));
        if(swapped)
          swap_segment_command(&sg, host_byte_sex);
        p = (char *)lc + sizeof(struct segment_command);
        for(j = 0 ; j < sg.nsects ; j++){
          memcpy((char *)&s, p, sizeof(struct section));
          p += sizeof(struct section);
          if(swapped)
            swap_section(&s, 1, host_byte_sex);
          section_type = s.flags & SECTION_TYPE;
          if((section_type == S_NON_LAZY_SYMBOL_POINTERS ||
              section_type == S_LAZY_SYMBOL_POINTERS ||
              section_type == S_LAZY_DYLIB_SYMBOL_POINTERS ||
              section_type == S_THREAD_LOCAL_VARIABLE_POINTERS ||
              section_type == S_SYMBOL_STUBS) &&
             value >= s.addr && value < s.addr + s.size){
            if(section_type == S_SYMBOL_STUBS)
              stride = s.reserved2;
            else
              stride = 4;
            index = s.reserved1 + (value - s.addr) / stride;
            if(index < nindirect_symbols &&
               symbols != NULL && strings != NULL &&
		           indirect_symbols[index] < nsymbols &&
		           (uint32_t)symbols[indirect_symbols[index]].
               n_un.n_strx < strings_size)
              return(strings +
                     symbols[indirect_symbols[index]].n_un.n_strx);
            else
              return(NULL);
          }
        }
        break;
	    case LC_SEGMENT_64:
        memcpy((char *)&sg64, (char *)lc,
               sizeof(struct segment_command_64));
        if(swapped)
          swap_segment_command_64(&sg64, host_byte_sex);
        p = (char *)lc + sizeof(struct segment_command_64);
        for(j = 0 ; j < sg64.nsects ; j++){
          memcpy((char *)&s64, p, sizeof(struct section_64));
          p += sizeof(struct section_64);
          if(swapped)
            swap_section_64(&s64, 1, host_byte_sex);
          section_type = s64.flags & SECTION_TYPE;
          if((section_type == S_NON_LAZY_SYMBOL_POINTERS ||
              section_type == S_LAZY_SYMBOL_POINTERS ||
              section_type == S_LAZY_DYLIB_SYMBOL_POINTERS ||
              section_type == S_THREAD_LOCAL_VARIABLE_POINTERS ||
              section_type == S_SYMBOL_STUBS) &&
             value >= s64.addr && value < s64.addr + s64.size){
            if(section_type == S_SYMBOL_STUBS)
              stride = s64.reserved2;
            else
              stride = 8;
            index = s64.reserved1 + (value - s64.addr) / stride;
            if(index < nindirect_symbols &&
               symbols64 != NULL && strings != NULL &&
		           indirect_symbols[index] < nsymbols &&
		           (uint32_t)symbols64[indirect_symbols[index]].
               n_un.n_strx < strings_size)
              return(strings +
                     symbols64[indirect_symbols[index]].n_un.n_strx);
            else
              return(NULL);
          }
        }
        break;
    }
    if(l.cmdsize == 0){
      return(NULL);
    }
    lc = (struct load_command *)((char *)lc + l.cmdsize);
    if((char *)lc > (char *)load_commands + sizeofcmds)
      return(NULL);
	}
	return(NULL);
}
