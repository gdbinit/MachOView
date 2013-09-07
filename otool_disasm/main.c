//
//  
//  some must have defines from the orogonal main.c
//
//  
//  
//

#include <stdio.h>
#include <stdlib.h>
#include <stuff/bool.h>

/* Name of this program for error messages (argv[0]) */
char *progname = NULL;

/*
 * The flags to indicate the actions to perform.
 */
enum bool fflag = FALSE; /* print the fat headers */
enum bool aflag = FALSE; /* print the archive header */
enum bool hflag = FALSE; /* print the exec or mach header */
enum bool lflag = FALSE; /* print the load commands */
enum bool Lflag = FALSE; /* print the shared library names */
enum bool Dflag = FALSE; /* print the shared library id name */
enum bool tflag = FALSE; /* print the text */
enum bool dflag = FALSE; /* print the data */
enum bool oflag = FALSE; /* print the objctive-C info */
enum bool Oflag = FALSE; /* print the objctive-C selector strings only */
enum bool rflag = FALSE; /* print the relocation entries */
enum bool Tflag = FALSE; /* print the dylib table of contents */
enum bool Mflag = FALSE; /* print the dylib module table */
enum bool Rflag = FALSE; /* print the dylib reference table */
enum bool Iflag = FALSE; /* print the indirect symbol table entries */
enum bool Hflag = FALSE; /* print the two-level hints table */
enum bool Sflag = FALSE; /* print the contents of the __.SYMDEF file */
enum bool vflag = TRUE; /* print verbosely (symbolically) when possible */
enum bool Vflag = TRUE; /* print dissassembled operands verbosely */
enum bool cflag = FALSE; /* print the argument and environ strings of a core */
enum bool iflag = FALSE; /* print the shared library initialization table */
enum bool Wflag = FALSE; /* print the mod time of an archive as a number */
enum bool Xflag = FALSE; /* don't print leading address in disassembly */
enum bool Zflag = FALSE; /* don't use simplified ppc mnemonics in disassembly */
enum bool Bflag = FALSE; /* force Thumb disassembly (ARM objects only) */
enum bool Qflag = FALSE; /* use the HACKED llvm-mc disassembler */
enum bool qflag = FALSE; /* use 'C' Public llvm-mc disassembler */
enum bool jflag = FALSE; /* print opcode bytes */
char *pflag = NULL; 	 /* procedure name to start disassembling from */
char *segname = NULL;	 /* name of the section to print the contents of */
char *sectname = NULL;
enum bool llvm_mc = FALSE; /* disassemble as llvm-mc will assemble */
