//
//  
//  some must have defines from the original main.c
//
//  
//  
//

#include <stdio.h>
#include <stdlib.h>
#include <mach-o/reloc.h>
#include "stuff/bool.h"
#include "stuff/symbol.h"

/* Name of this program for error messages (argv[0]) */
char *progname = NULL;

/*
 * The flags to indicate the actions to perform.
 */
enum bool eflag = FALSE; /* print enhanced disassembly */
enum bool Xflag = FALSE; /* don't print leading address in disassembly */
enum bool Bflag = FALSE; /* force Thumb disassembly (ARM objects only) */
enum bool qflag = FALSE; /* use 'C' Public llvm-mc disassembler */
enum bool gflag = FALSE; /* group the disassembly */
enum bool nflag = FALSE; /* use intel disassembly syntax */
char *mcpu = "";	/* the arg of the -mcpu=arg flag */

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