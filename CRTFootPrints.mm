/*
 *  CRTFootPrints.mm
 *  MachOView
 *
 *  Created by psaghelyi on 25/11/2010.
 *
 */

#import "CRTFootPrints.h"
#import "DataController.h"

#define MATCHASM(_pattern) \
  (offset + sizeof(_pattern) < dataLength && \
  [self matchAsmAtOffset:offset asmFootPrint:_pattern lineCount:sizeof(_pattern)/FOOTPRINT_STRIDE])


using namespace std;

//**********************************************************************
//                             crt1 footprints
//**********************************************************************

//==================================
// SDK:10.4 DeployTarget:10.4
// MacOSX10.4u.sdk/usr/lib/crt1.o
//==================================
static AsmFootPrint const SDK104Target104X86v1 =
{
  //start:
  {2, 0x6A, 0x00},                          // push    0
  {2, 0x89, 0xE5},                          // mov     ebp, esp
  {3, 0x83, 0xE4 ,0xF0},                    // and     esp, 0FFFFFFF0h
  {3, 0x83, 0xEC ,0x10},                    // sub     esp, 10h
  {3, 0x8B, 0x5D ,0x04},                    // mov     ebx, [ebp+4]
  {4, 0x89, 0x5C ,0x24 ,0x00},              // mov     [esp+14h+var_14], ebx
  {3, 0x8D, 0x4D ,0x08},                    // lea     ecx, [ebp+8]
  {4, 0x89, 0x4C ,0x24 ,0x04},              // mov     [esp+14h+var_10], ecx
  {3, 0x83, 0xC3 ,0x01},                    // add     ebx, 1
  {3, 0xC1, 0xE3 ,0x02},                    // shl     ebx, 2
  {2, 0x01, 0xCB},                          // add     ebx, ecx
  {4, 0x89, 0x5C ,0x24 ,0x08},              // mov     [esp+14h+var_C], ebx
  {5, 0xE8, 0x01 ,0x00 ,0x00 ,0x00},        // call    __start
  {1, 0xF4},                                // hlt

  //__start:
  {1, 0x55},                                // push    ebp
  {2, 0x89, 0xE5},                          // mov     ebp, esp
  {1, 0x57},                                // push    edi
  {1, 0x56},                                // push    esi
  {1, 0x53},                                // push    ebx
  {3, 0x83, 0xEC, 0x2C},                    // sub     esp, 2Ch
  {1, 0xE8}, GAP(4),                        // call    sub_120AD8
  {3, 0x8B, 0x45, 0x08},                    // mov     eax, [ebp+arg_0]
  {2, 0x89, 0x83}, GAP(4),                  // mov     ds:(_NXArgc - 2C28h)[ebx], eax
  {3, 0x8B, 0x45, 0x0C},                    // mov     eax, [ebp+arg_4]
  {2, 0x89, 0x83}, GAP(4),                  // mov     ds:(_NXArgv - 2C28h)[ebx], eax
  {3, 0x8B, 0x45, 0x10},                    // mov     eax, [ebp+arg_8]
  {2, 0x89, 0x83}, GAP(4),                  // mov     ds:(_environ - 2C28h)[ebx], eax
  {2, 0x8B, 0x83}, GAP(4),                  // mov     eax, ds:(_mach_init_routine_ptr - 2C28h)[ebx]
  {2, 0x8B, 0x00},                          // mov     eax, [eax]
  {2, 0x85, 0xC0},                          // test    eax, eax
  {2, 0x74, 0x02},                          // jz      short loc_2C51
  {2, 0xFF, 0xD0},                          // call    eax

  //loc_2C51: 
  {2, 0x8B, 0x83}, GAP(4),                  // mov     eax, ds:(__cthread_init_routine_ptr - 2C28h)[ebx]
  {2, 0x8B, 0x00},                          // mov     eax, [eax]
  {2, 0x85, 0xC0},                          // test    eax, eax
  {2, 0x74, 0x02},                          // jz      short loc_2C5F
  {2, 0xFF, 0xD0},                          // call    eax

  //loc_2C5F:
  {1, 0xE8}, GAP(4),                        // call    ___keymgr_dwarf2_register_sections
  {5, 0xE8, 0xB0, 0x00, 0x00, 0x00},        // call    sub_2D19
  {3, 0x8D, 0x45, 0xE4},                    // lea     eax, [ebp+var_1C]
  {4, 0x89, 0x44, 0x24, 0x04},              // mov     [esp+4], eax
  {2, 0x8D, 0x83}, GAP(4),                  // lea     eax, (a__dyld_mod_ter - 2C28h)[ebx] ; "__dyld_mod_term_funcs"
  {3, 0x89, 0x04, 0x24},                    // mov     [esp], eax
  {5, 0xE8, 0xD2, 0x00, 0x00, 0x00},        // call    sub_2D50
  {3, 0x8B, 0x45, 0xE4},                    // mov     eax, [ebp+var_1C]
  {2, 0x85, 0xC0},                          // test    eax, eax
  {2, 0x74, 0x08},                          // jz      short loc_2C8D
  {3, 0x89, 0x04, 0x24},                    // mov     [esp], eax      ; void (*)(void)
  {1, 0xE8}, GAP(4),                        // call    _atexit

  //loc_2C8D:
  {2, 0x8B, 0x83}, GAP(4),                  // mov     eax, ds:(_errno_ptr - 2C28h)[ebx]
  {6, 0xC7, 0x00, 0x00, 0x00, 0x00, 0x00},  // mov     dword ptr [eax], 0
  {3, 0x8B, 0x45, 0x0C},                    // mov     eax, [ebp+arg_4]
  {2, 0x8B, 0x38},                          // mov     edi, [eax]
  {2, 0x85, 0xFF},                          // test    edi, edi
  {2, 0x75, 0x64},                          // jnz     short loc_2D06
  {2, 0xEB, 0x27},                          // jmp     short loc_2CCB
  // ---------------------------------------------------------------------------

  //loc_2CA4:
  {3, 0x80, 0xF9, 0x2F},                    // cmp     cl, 2Fh
  {3, 0x0F, 0x44, 0xC2},                    // cmovz   eax, edx
  {2, 0x89, 0xF2},                          // mov     edx, esi
  {3, 0x0F, 0xB6, 0x0E},                    // movzx   ecx, byte ptr [esi]
  {3, 0x8D, 0x76, 0x01},                    // lea     esi, [esi+1]
  {2, 0x84, 0xC9},                          // test    cl, cl
  {2, 0x75, 0xEE},                          // jnz     short loc_2CA4
  {2, 0x85, 0xC0},                          // test    eax, eax
  {2, 0x74, 0x0B},                          // jz      short loc_2CC5
  {3, 0x83, 0xC0, 0x01},                    // add     eax, 1
  {2, 0x89, 0x83}, GAP(4),                  // mov     ds:(___progname - 2C28h)[ebx], eax
  {2, 0xEB, 0x06},                          // jmp     short loc_2CCB
  // ---------------------------------------------------------------------------

  //loc_2CC5:
  {2, 0x89, 0xBB}, GAP(4),                  // mov     ds:(___progname - 2C28h)[ebx], edi

  //loc_2CCB:
  {3, 0x8B, 0x45, 0x10},                    // mov     eax, [ebp+arg_8]
  {3, 0x83, 0x38, 0x00},                    // cmp     dword ptr [eax], 0
  {2, 0x74, 0x0B},                          // jz      short loc_2CDE
  {3, 0x8B, 0x45, 0x10},                    // mov     eax, [ebp+arg_8]

  //loc_2CD6:
  {3, 0x83, 0xC0, 0x04},                    // add     eax, 4
  {3, 0x83, 0x38, 0x00},                    // cmp     dword ptr [eax], 0
  {2, 0x75, 0xF8},                          // jnz     short loc_2CD6

  //loc_2CDE:
  {3, 0x83, 0xC0, 0x04},                    // add     eax, 4
  {4, 0x89, 0x44, 0x24, 0x0C},              // mov     [esp+0Ch], eax
  {3, 0x8B, 0x45, 0x10},                    // mov     eax, [ebp+arg_8]
  {4, 0x89, 0x44, 0x24, 0x08},              // mov     [esp+8], eax
  {3, 0x8B, 0x45, 0x0C},                    // mov     eax, [ebp+arg_4]
  {4, 0x89, 0x44, 0x24, 0x04},              // mov     [esp+4], eax
  {3, 0x8B, 0x45, 0x08},                    // mov     eax, [ebp+arg_0]
  {3, 0x89, 0x04, 0x24},                    // mov     [esp], eax
  {1, 0xE8}, GAP(4),                        // call    _main
  {3, 0x89, 0x04, 0x24},                    // mov     [esp], eax      ; int
  {1, 0xE8}, GAP(4),                        // call    _exit
  // ---------------------------------------------------------------------------
  
  //loc_2D06:
  {3, 0x0F, 0xB6, 0x0F},                    // movzx   ecx, byte ptr [edi]
  {2, 0x84, 0xC9},                          // test    cl, cl
  {2, 0x74, 0xB8},                          // jz      short loc_2CC5
  {3, 0x8D, 0x77, 0x01},                    // lea     esi, [edi+1]
  {2, 0x89, 0xFA},                          // mov     edx, edi
  {5, 0xB8, 0x00, 0x00, 0x00, 0x00},        // mov     eax, 0
  {2, 0xEB, 0x8B},                          // jmp     short loc_2CA4
  
  //sub_2D19:
  {1, 0x55},                                // push    ebp
  {2, 0x89, 0xE5},                          // mov     ebp, esp
  {1, 0x53},                                // push    ebx
  {3, 0x83, 0xEC, 0x24},                    // sub     esp, 24h
  {1, 0xE8}, GAP(4),                        // call    sub_120AD8
  {3, 0x8D, 0x45, 0xF4},                    // lea     eax, [ebp+var_C]
  {4, 0x89, 0x44, 0x24, 0x04},              // mov     [esp+4], eax
  {2, 0x8D, 0x83}, GAP(4),                  // lea     eax, (a__dyld_make_de - 2D25h)[ebx] ; "__dyld_make_delayed_module_initializer_"...
  {3, 0x89, 0x04, 0x24},                    // mov     [esp], eax
  {5, 0xE8, 0x16, 0x00, 0x00, 0x00},        // call    sub_2D50
  {3, 0xFF, 0x55, 0xF4},                    // call    [ebp+var_C]
  {3, 0x83, 0xC4, 0x24},                    // add     esp, 24h
  {1, 0x5B},                                // pop     ebx
  {1, 0x5D},                                // pop     ebp
  {1, 0xC3},                                // retn
  // ---------------------------------------------------------------------------
  {1, 0x90},                                // nop
  {5, 0x68, 0x00, 0x10, 0x00, 0x00},        // push    1000h
  {2, 0xFF, 0x25}, GAP(4),                  // jmp     ds:dword_150010
  // ---------------------------------------------------------------------------
  {1, 0x90},                                // nop
 
  //sub_2D50:
  {2, 0xFF, 0x25}, GAP(4),                  // jmp     ds:dword_150014
};  


static AsmFootPrint const SDK104Target104X86v2 =
{
  //start:
  {2, 0x6A, 0x00},                          // push    0
  {2, 0x89, 0xE5},                          // mov     ebp, esp
  {3, 0x83, 0xE4, 0xF0},                    // and     esp, 0FFFFFFF0h
  {3, 0x83, 0xEC, 0x10},                    // sub     esp, 10h
  {3, 0x8B, 0x5D, 0x04},                    // mov     ebx, [ebp+4]
  {4, 0x89, 0x5C, 0x24, 0x00},              // mov     [esp+14h+var_14], ebx
  {3, 0x8D, 0x4D, 0x08},                    // lea     ecx, [ebp+8]
  {4, 0x89, 0x4C, 0x24, 0x04},              // mov     [esp+14h+var_10], ecx
  {3, 0x83, 0xC3, 0x01},                    // add     ebx, 1
  {3, 0xC1, 0xE3, 0x02},                    // shl     ebx, 2
  {2, 0x01, 0xCB},                          // add     ebx, ecx
  {4, 0x89, 0x5C, 0x24, 0x08},              // mov     [esp+14h+var_C], ebx
  {5, 0xE8, 0x01, 0x00, 0x00, 0x00},        // call    __start
  {1, 0xF4},                                // hlt
  
  //__start:
  {1, 0x55},                                // push    ebp
  {2, 0x89, 0xE5},                          // mov     ebp, esp
  {1, 0x57},                                // push    edi
  {1, 0x56},                                // push    esi
  {1, 0x53},                                // push    ebx
  {3, 0x83, 0xEC, 0x2C},                    // sub     esp, 2Ch
  {3, 0x8B, 0x7D, 0x0C},                    // mov     edi, [ebp+arg_4]
  {3, 0x8B, 0x5D, 0x10},                    // mov     ebx, [ebp+arg_8]
  {3, 0x8B, 0x45, 0x08},                    // mov     eax, [ebp+arg_0]
  {1, 0xA3}, GAP(4),                        // mov     ds:_NXArgc, eax
  {2, 0x89, 0x3D}, GAP(4),                  // mov     ds:_NXArgv, edi
  {2, 0x89, 0x1D}, GAP(4),                  // mov     ds:_environ, ebx
  {2, 0x8B, 0x0F},                          // mov     ecx, [edi]
  {2, 0x85, 0xC9},                          // test    ecx, ecx
  {2, 0x75, 0x07},                          // jnz     short loc_5A
  {1, 0xB9}, GAP(4),                        // mov     ecx, offset byte_120
  {2, 0xEB, 0x19},                          // jmp     short loc_73
  // ---------------------------------------------------------------------------
  
  //loc_5A:
  {2, 0x89, 0xCA},                          // mov     edx, ecx
  {2, 0xEB, 0x0E},                          // jmp     short loc_6C
  // ---------------------------------------------------------------------------
  
  //loc_5E:
  {2, 0x3C, 0x2F},                          // cmp     al, 2Fh ; '/'
  {2, 0x74, 0x05},                          // jz      short loc_67
  {3, 0x83, 0xC2, 0x01},                    // add     edx, 1
  {2, 0xEB, 0x05},                          // jmp     short loc_6C
  // ---------------------------------------------------------------------------
  
  //loc_67:
  {3, 0x83, 0xC2, 0x01},                    // add     edx, 1
  {2, 0x89, 0xD1},                          // mov     ecx, edx
  
  //loc_6C:
  {3, 0x0F, 0xB6, 0x02},                    // movzx   eax, byte ptr [edx]
  {2, 0x84, 0xC0},                          // test    al, al
  {2, 0x75, 0xEB},                          // jnz     short loc_5E
  
  //loc_73:
  {2, 0x89, 0x0D}, GAP(4),                  // mov     ds:___progname, ecx
  {2, 0x89, 0xD8},                          // mov     eax, ebx
  {2, 0xEB, 0x03},                          // jmp     short loc_80
  // ---------------------------------------------------------------------------
  
  //loc_7D:
  {3, 0x83, 0xC0, 0x04},                    // add     eax, 4
  
  //loc_80:
  {2, 0x8B, 0x10},                          // mov     edx, [eax]
  {2, 0x85, 0xD2},                          // test    edx, edx
  {2, 0x75, 0xF7},                          // jnz     short loc_7D
  {3, 0x8D, 0x70, 0x04},                    // lea     esi, [eax+4]
  {1, 0xA1}, GAP(4),                        // mov     eax, ds:_mach_init_routine_ptr
  {2, 0x8B, 0x00},                          // mov     eax, [eax]
  {2, 0x85, 0xC0},                          // test    eax, eax
  {2, 0x74, 0x02},                          // jz      short loc_96
  {2, 0xFF, 0xD0},                          // call    eax
  
  //loc_96:
  {1, 0xA1}, GAP(4),                        // mov     eax, ds:__cthread_init_routine_ptr
  {2, 0x8B, 0x00},                          // mov     eax, [eax]
  {2, 0x85, 0xC0},                          // test    eax, eax
  {2, 0x74, 0x02},                          // jz      short loc_A3
  {2, 0xFF, 0xD0},                          // call    eax
  
  //loc_A3:
  {1, 0xE8}, GAP(4),                        // call    ___keymgr_dwarf2_register_sections
  {3, 0x8D, 0x45, 0xE0},                    // lea     eax, [ebp+var_20]
  {4, 0x89, 0x44, 0x24, 0x04},              // mov     [esp+4], eax
  {3, 0xC7, 0x04, 0x24}, GAP(4),            // mov     dword ptr [esp], offset a__dyld_make_de ; "__dyld_make_delayed_module_initializer_"...
  {1, 0xE8}, GAP(4),                        // call    __dyld_func_lookup
  {3, 0xFF, 0x55, 0xE0},                    // call    [ebp+var_20]
  {3, 0x8D, 0x45, 0xE4},                    // lea     eax, [ebp+var_1C]
  {4, 0x89, 0x44, 0x24, 0x04},              // mov     [esp+4], eax
  {3, 0xC7, 0x04, 0x24}, GAP(4),            // mov     dword ptr [esp], offset a__dyld_mod_ter ; "__dyld_mod_term_funcs"
  {1, 0xE8}, GAP(4),                        // call    __dyld_func_lookup
  {3, 0x8B, 0x45, 0xE4},                    // mov     eax, [ebp+var_1C]
  {2, 0x85, 0xC0},                          // test    eax, eax
  {2, 0x74, 0x08},                          // jz      short loc_E0
  {3, 0x89, 0x04, 0x24},                    // mov     [esp], eax      ; void (*)(void)
  {1, 0xE8}, GAP(4),                        // call    _atexit
  
  //loc_E0:
  {1, 0xA1}, GAP(4),                        // mov     eax, ds:_errno_ptr
  {6, 0xC7, 0x00, 0x00, 0x00, 0x00, 0x00},  // mov     dword ptr [eax], 0
  {4, 0x89, 0x74, 0x24, 0x0C},              // mov     [esp+0Ch], esi
  {4, 0x89, 0x5C, 0x24, 0x08},              // mov     [esp+8], ebx
  {4, 0x89, 0x7C, 0x24, 0x04},              // mov     [esp+4], edi
  {3, 0x8B, 0x45, 0x08},                    // mov     eax, [ebp+arg_0]
  {3, 0x89, 0x04, 0x24},                    // mov     [esp], eax
  {1, 0xE8}, GAP(4),                        // call    _main
  {3, 0x89, 0x04, 0x24},                    // mov     [esp], eax      ; int
  {1, 0xE8}, GAP(4),                        // call    _exit
};

static AsmFootPrint const SDK104Target104X86v3 =
{
  //start:
  {2, 0x6A, 0x00},                          // push    0
  {2, 0x89, 0xE5},                          // mov     ebp, esp
  {3, 0x83, 0xE4, 0xF0},                    // and     esp, 0FFFFFFF0h
  {3, 0x83, 0xEC, 0x10},                    // sub     esp, 10h
  {3, 0x8B, 0x5D, 0x04},                    // mov     ebx, [ebp+4]
  {4, 0x89, 0x5C, 0x24, 0x00},              // mov     [esp+0], ebx
  {3, 0x8D, 0x4D, 0x08},                    // lea     ecx, [ebp+8]
  {4, 0x89, 0x4C, 0x24, 0x04},              // mov     [esp+4], ecx
  {3, 0x83, 0xC3, 0x01},                    // add     ebx, 1
  {3, 0xC1, 0xE3, 0x02},                    // shl     ebx, 2
  {2, 0x01, 0xCB},                          // add     ebx, ecx
  {4, 0x89, 0x5C, 0x24, 0x08},              // mov     [esp+8], ebx
  {5, 0xE8, 0x01, 0x00, 0x00, 0x00},        // call    __start
  {1, 0xF4},                                // hlt
  
  
  //__start:
  {1, 0x55},                                // push    ebp
  {2, 0x89, 0xE5},                          // mov     ebp, esp
  {1, 0x57},                                // push    edi
  {1, 0x56},                                // push    esi
  {1, 0x53},                                // push    ebx
  {3, 0x83, 0xEC, 0x2C},                    // sub     esp, 2Ch
  {3, 0x8B, 0x75, 0x0C},                    // mov     esi, [ebp+0Ch]
  {3, 0x8B, 0x5D, 0x10},                    // mov     ebx, [ebp+10h]
  {3, 0x8B, 0x45, 0x08},                    // mov     eax, [ebp+8]
  {2, 0x89, 0x35}, GAP(4),                  // mov     ds:_NXArgv, esi
  {2, 0x89, 0x1D}, GAP(4),                  // mov     ds:_environ, ebx
  {1, 0xA3}, GAP(4),                        // mov     ds:_NXArgc, eax
  {2, 0x8B, 0x0E},                          // mov     ecx, [esi]
  {2, 0x85, 0xC9},                          // test    ecx, ecx
  {2, 0x89, 0xCA},                          // mov     edx, ecx
  {2, 0x75, 0x11},                          // jnz     short loc_26BA
  {1, 0xB9}, GAP(4),                        // mov     ecx, offset unk_13C874
  {2, 0xEB, 0x11},                          // jmp     short loc_26C1
  // ---------------------------------------------------------------------------
  
  //loc_26B0:
  {2, 0x3C, 0x2F},                          // cmp     al, 2Fh
  {2, 0x74, 0x03},                          // jz      short loc_26B7
  {1, 0x42},                                // inc     edx
  {2, 0xEB, 0x03},                          // jmp     short loc_26BA
  // ---------------------------------------------------------------------------
  
  //loc_26B7:
  {1, 0x42},                                // inc     edx
  {2, 0x89, 0xD1},                          // mov     ecx, edx
  
  //loc_26BA:
  {3, 0x0F, 0xB6, 0x02},                    // movzx   eax, byte ptr [edx]
  {2, 0x84, 0xC0},                          // test    al, al
  {2, 0x75, 0xEF},                          // jnz     short loc_26B0
  
  //loc_26C1:
  {2, 0x89, 0xD8},                          // mov     eax, ebx
  {2, 0x89, 0x0D}, GAP(4),                  // mov     ds:___progname, ecx
  {2, 0xEB, 0x03},                          // jmp     short loc_26CE
  // ---------------------------------------------------------------------------
  
  //loc_26CB:
  {3, 0x83, 0xC0, 0x04},                    // add     eax, 4
  
  //loc_26CE:
  {2, 0x8B, 0x10},                          // mov     edx, [eax]
  {2, 0x85, 0xD2},                          // test    edx, edx
  {2, 0x75, 0xF7},                          // jnz     short loc_26CB
  {3, 0x8D, 0x78, 0x04},                    // lea     edi, [eax+4]
  {1, 0xA1}, GAP(4),                        // mov     eax, ds:_mach_init_routine_ptr
  {2, 0x8B, 0x00},                          // mov     eax, [eax]
  {2, 0x85, 0xC0},                          // test    eax, eax
  {2, 0x74, 0x02},                          // jz      short loc_26E4
  {2, 0xFF, 0xD0},                          // call    eax
  
  //loc_26E4:
  {1, 0xA1}, GAP(4),                        // mov     eax, ds:__cthread_init_routine_ptr
  {2, 0x8B, 0x00},                          // mov     eax, [eax]
  {2, 0x85, 0xC0},                          // test    eax, eax
  {2, 0x74, 0x02},                          // jz      short loc_26F1
  {2, 0xFF, 0xD0},                          // call    eax
  
  //loc_26F1:
  {1, 0xE8}, GAP(4),                        // call    ___keymgr_dwarf2_register_sections
  {3, 0x8D, 0x45, 0xE0},                    // lea     eax, [ebp-20h]
  {4, 0x89, 0x44, 0x24, 0x04},              // mov     [esp+4], eax
  {3, 0xC7, 0x04, 0x24}, GAP(4),            // mov     dword ptr [esp], offset a__dyld_make_de ; "__dyld_make_delayed_module_initializer_"...
  {1, 0xE8}, GAP(4),                        // call    __dyld_func_lookup
  {3, 0xFF, 0x55, 0xE0},                    // call    dword ptr [ebp-20h]
  {3, 0x8D, 0x45, 0xE4},                    // lea     eax, [ebp-1Ch]
  {4, 0x89, 0x44, 0x24, 0x04},              // mov     [esp+4], eax
  {3, 0xC7, 0x04, 0x24}, GAP(4),            // mov     dword ptr [esp], offset a__dyld_mod_ter ; "__dyld_mod_term_funcs"
  {1, 0xE8}, GAP(4),                        // call    __dyld_func_lookup
  {3, 0x8B, 0x45, 0xE4},                    // mov     eax, [ebp-1Ch]
  {2, 0x85, 0xC0},                          // test    eax, eax
  {2, 0x74, 0x08},                          // jz      short loc_272E
  {3, 0x89, 0x04, 0x24},                    // mov     [esp], eax
  {1, 0xE8}, GAP(4),                        // call    _atexit
  
  //loc_272E:
  {1, 0xA1}, GAP(4),                        // mov     eax, ds:_errno_ptr
  {6, 0xC7, 0x00, 0x00, 0x00, 0x00, 0x00},  // mov     dword ptr [eax], 0
  {3, 0x8B, 0x45, 0x08},                    // mov     eax, [ebp+8]
  {4, 0x89, 0x7C, 0x24, 0x0C},              // mov     [esp+0Ch], edi
  {4, 0x89, 0x5C, 0x24, 0x08},              // mov     [esp+8], ebx
  {4, 0x89, 0x74, 0x24, 0x04},              // mov     [esp+4], esi
  {3, 0x89, 0x04, 0x24},                    // mov     [esp], eax
  {1, 0xE8}, GAP(4),                        // call    _main
  {3, 0x89, 0x04, 0x24},                    // mov     [esp], eax
  {1, 0xE8}, GAP(4),                        // call    _exit
};

static AsmFootPrint const SDK104Target104X86v4 =
{
  //start:
  {2, 0x6A, 0x00},                          // push    0
  {2, 0x89, 0xE5},                          // mov     ebp, esp
  {3, 0x83, 0xE4, 0xF0},                    // and     esp, 0FFFFFFF0h
  {3, 0x83, 0xEC, 0x10},                    // sub     esp, 10h
  {3, 0x8B, 0x5D, 0x04},                    // mov     ebx, [ebp+4]
  {3, 0x89, 0x1C, 0x24},                    // mov     [esp+14h+var_14], ebx
  {3, 0x8D, 0x4D, 0x08},                    // lea     ecx, [ebp+8]
  {4, 0x89, 0x4C, 0x24, 0x04},              // mov     [esp+14h+var_10], ecx
  {3, 0x83, 0xC3, 0x01},                    // add     ebx, 1
  {3, 0xC1, 0xE3, 0x02},                    // shl     ebx, 2
  {2, 0x01, 0xCB},                          // add     ebx, ecx
  {4, 0x89, 0x5C, 0x24, 0x08},              // mov     [esp+14h+var_C], ebx
  {5, 0xE8, 0x01, 0x00, 0x00, 0x00},        // call    __start
  {1, 0xF4},                                // hlt
  
  //__start:
  {1, 0x55},                                // push    ebp
  {2, 0x89, 0xE5},                          // mov     ebp, esp
  {1, 0x53},                                // push    ebx
  {1, 0x57},                                // push    edi
  {1, 0x56},                                // push    esi
  {3, 0x83, 0xEC, 0x1C},                    // sub     esp, 1Ch
  {3, 0x8B, 0x45, 0x08},                    // mov     eax, [ebp+arg_0]
  {1, 0xA3}, GAP(4),                        // mov     ds:_NXArgc, eax
  {3, 0x8B, 0x75, 0x0C},                    // mov     esi, [ebp+arg_4]
  {2, 0x89, 0x35}, GAP(4),                  // mov     ds:_NXArgv, esi
  {3, 0x8B, 0x7D, 0x10},                    // mov     edi, [ebp+arg_8]
  {2, 0x89, 0x3D}, GAP(4),                  // mov     ds:_environ, edi
  {2, 0x8B, 0x06},                          // mov     eax, [esi]
  {2, 0x85, 0xC0},                          // test    eax, eax
  {2, 0x75, 0x07},                          // jnz     short loc_20D9
  {1, 0xB8}, GAP(4),                        // mov     eax, 3BF300h
  {2, 0xEB, 0x28},                          // jmp     short loc_2101
  // ---------------------------------------------------------------------------
  
  // loc_20D9:
  {2, 0x8A, 0x08},                          // mov     cl, [eax]
  {2, 0x84, 0xC9},                          // test    cl, cl
  {2, 0x74, 0x22},                          // jz      short loc_2101
  {3, 0x8A, 0x50, 0x01},                    // mov     dl, [eax+1]
  {3, 0x8D, 0x58, 0x01},                    // lea     ebx, [eax+1]
  {3, 0x80, 0xF9, 0x2F},                    // cmp     cl, 2Fh
  {3, 0x0F, 0x45, 0xD8},                    // cmovnz  ebx, eax
  {2, 0x84, 0xD2},                          // test    dl, dl
  {2, 0x74, 0x10},                          // jz      short loc_20FF
  {3, 0x83, 0xC0, 0x02},                    // add     eax, 2
  
  // loc_20F2:
  {3, 0x80, 0xFA, 0x2F},                    // cmp     dl, 2Fh
  {3, 0x0F, 0x44, 0xD8},                    // cmovz   ebx, eax
  {2, 0x8A, 0x10},                          // mov     dl, [eax]
  {1, 0x40},                                // inc     eax
  {2, 0x84, 0xD2},                          // test    dl, dl
  {2, 0x75, 0xF3},                          // jnz     short loc_20F2
  
  // loc_20FF:
  {2, 0x89, 0xD8},                          // mov     eax, ebx
  
  // loc_2101:
  
  {1, 0xA3}, GAP(4),                        // mov     ds:___progname, eax
  {2, 0x89, 0xFB},                          // mov     ebx, edi
  
  // loc_2108:
  {3, 0x83, 0x3B, 0x00},                    // cmp     dword ptr [ebx], 0
  {3, 0x8D, 0x5B, 0x04},                    // lea     ebx, [ebx+4]
  {2, 0x75, 0xF8},                          // jnz     short loc_2108
  {1, 0xA1}, GAP(4),                        // mov     eax, ds:_mach_init_routine_ptr
  {2, 0x8B, 0x00},                          // mov     eax, [eax]
  {2, 0x85, 0xC0},                          // test    eax, eax
  {2, 0x74, 0x02},                          // jz      short loc_211D
  {2, 0xFF, 0xD0},                          // call    eax
  
  // loc_211D:
  {1, 0xA1}, GAP(4),                        // mov     eax, ds:__cthread_init_routine_ptr
  {2, 0x8B, 0x00},                          // mov     eax, [eax]
  {2, 0x85, 0xC0},                          // test    eax, eax
  {2, 0x74, 0x02},                          // jz      short loc_212A
  {2, 0xFF, 0xD0},                          // call    eax
  
  // loc_212A:
  {1, 0xE8}, GAP(4),                        // call    ___keymgr_dwarf2_register_sections
  {3, 0x8D, 0x45, 0xEC},                    // lea     eax, [ebp+var_14]
  {4, 0x89, 0x44, 0x24, 0x04},              // mov     [esp+4], eax
  {3, 0xC7, 0x04, 0x24}, GAP(4),            // mov     dword ptr [esp], offset a__dyld_make_de ; "__dyld_make_delayed_module_initializer_"...
  {1, 0xE8}, GAP(4),                        // call    __dyld_func_lookup
  {3, 0xFF, 0x55, 0xEC},                    // call    [ebp+var_14]
  {3, 0x8D, 0x45, 0xF0},                    // lea     eax, [ebp+var_10]
  {4, 0x89, 0x44, 0x24, 0x04},              // mov     [esp+4], eax
  {3, 0xC7, 0x04, 0x24}, GAP(4),            // mov     dword ptr [esp], offset a__dyld_mod_ter ; "__dyld_mod_term_funcs"
  {1, 0xE8}, GAP(4),                        // call    __dyld_func_lookup
  {3, 0x8B, 0x45, 0xF0},                    // mov     eax, [ebp+var_10]
  {2, 0x85, 0xC0},                          // test    eax, eax
  {2, 0x74, 0x08},                          // jz      short loc_2167
  {3, 0x89, 0x04, 0x24},                    // mov     [esp], eax      ; void (*)(void)
  {1, 0xE8}, GAP(4),                        // call    _atexit
  
  // loc_2167:
  {1, 0xA1}, GAP(4),                        // mov     eax, ds:_errno_ptr
  {6, 0xC7, 0x00, 0x00, 0x00, 0x00, 0x00},  // mov     dword ptr [eax], 0
  {4, 0x89, 0x5C, 0x24, 0x0C},              // mov     [esp+0Ch], ebx
  {4, 0x89, 0x7C, 0x24, 0x08},              // mov     [esp+8], edi
  {4, 0x89, 0x74, 0x24, 0x04},              // mov     [esp+4], esi
  {3, 0x8B, 0x4D, 0x08},                    // mov     ecx, [ebp+arg_0]
  {3, 0x89, 0x0C, 0x24},                    // mov     [esp], ecx
  {1, 0xE8}, GAP(4),                        // call    _main
  {3, 0x89, 0x04, 0x24},                    // mov     [esp], eax      ; int
  {1, 0xE8}, GAP(4),                        // call    _exit
};

static AsmFootPrint const SDK104Target104X86_64 =
{
  //start:
  {2, 0x6A, 0x00},                          // push    0
  {3, 0x48, 0x89, 0xE5},                    // mov     rbp, rsp
  {4, 0x48, 0x83, 0xE4, 0xF0},              // and     rsp, 0FFFFFFFFFFFFFFF0h
  {4, 0x48, 0x8B, 0x7D, 0x08},              // mov     rdi, [rbp+8]
  {4, 0x48, 0x8D, 0x75, 0x10},              // lea     rsi, [rbp+10h]
  {2, 0x89, 0xFA,},                         // mov     edx, edi
  {3, 0x83, 0xC2, 0x01},                    // add     edx, 1
  {3, 0xC1, 0xE2, 0x03},                    // shl     edx, 3
  {3, 0x48, 0x01, 0xF2},                    // add     rdx, rsi
  {5, 0xE8, 0x01, 0x00, 0x00, 0x00},        // call    __start
  {1, 0xF4},                                // hlt

  //__start
  {1, 0x55},                                // push    rbp
  {3, 0x48, 0x89, 0xE5},                    // mov     rbp, rsp
  {2, 0x41, 0x56},                          // push    r14
  {2, 0x41, 0x55},                          // push    r13
  {2, 0x41, 0x54},                          // push    r12
  {1, 0x53},                                // push    rbx
  {4, 0x48, 0x83, 0xEC, 0x10},              // sub     rsp, 10h
  {3, 0x41, 0x89, 0xFE},                    // mov     r14d, edi
  {3, 0x49, 0x89, 0xF4},                    // mov     r12, rsi
  {3, 0x48, 0x89, 0xD3},                    // mov     rbx, rdx
  {2, 0x89, 0x3D}, GAP(4),                  // mov     cs:_NXArgc, edi
  {3, 0x48, 0x89, 0x35}, GAP(4),            // mov     cs:_NXArgv, rsi
  {3, 0x48, 0x89, 0x15}, GAP(4),            // mov     cs:_environ, rdx
  {3, 0x48, 0x8B, 0x0E},                    // mov     rcx, [rsi]
  {3, 0x48, 0x85, 0xC9},                    // test    rcx, rcx
  {2, 0x75, 0x09},                          // jnz     short loc_5F
  {3, 0x48, 0x8D, 0x0D}, GAP(4),            // lea     rcx, byte_180
  {2, 0xEB, 0x1D},                          // jmp     short loc_7C
  // ---------------------------------------------------------------------------

  // loc_5F
  {3, 0x48, 0x89, 0xCA},                    // mov     rdx, rcx
  {2, 0xEB, 0x11},                          // jmp     short loc_75
  // ---------------------------------------------------------------------------

  // loc_64
  {2, 0x3C, 0x2F},                          // cmp     al, 2Fh ; '/'
  {2, 0x74, 0x06},                          // jz      short loc_6E
  {4, 0x48, 0x83, 0xC2, 0x01},              // add     rdx, 1
  {2, 0xEB, 0x07},                          // jmp     short loc_75
  // ---------------------------------------------------------------------------

  // loc_6E
  {4, 0x48, 0x83, 0xC2, 0x01},              // add     rdx, 1
  {3, 0x48, 0x89, 0xD1},                    // mov     rcx, rdx

  // loc_75
  {3, 0x0F, 0xB6, 0x02},                    // movzx   eax, byte ptr [rdx]
  {2, 0x84, 0xC0},                          // test    al, al
  {2, 0x75, 0xE8},                          // jnz     short loc_64

  // loc_7C
  {3, 0x48, 0x89, 0x0D}, GAP(4),            // mov     cs:___progname, rcx
  {3, 0x48, 0x89, 0xD8},                    // mov     rax, rbx
  {2, 0xEB, 0x04},                          // jmp     short loc_8C
  // ---------------------------------------------------------------------------

  // loc_88
  {4, 0x48, 0x83, 0xC0, 0x08},              // add     rax, 8

  // loc_8C
  {4, 0x48, 0x83, 0x38, 0x00},              // cmp     qword ptr [rax], 0
  {2, 0x75, 0xF6},                          // jnz     short loc_88
  {4, 0x4C, 0x8D, 0x68, 0x08},              // lea     r13, [rax+8]
  {3, 0x48, 0x8B, 0x05}, GAP(4),            // mov     rax, cs:_mach_init_routine
  {3, 0x48, 0x8B, 0x00},                    // mov     rax, [rax]
  {3, 0x48, 0x85, 0xC0},                    // test    rax, rax
  {2, 0x74, 0x02},                          // jz      short loc_A7
  {2, 0xFF, 0xD0},                          // call    rax

  // loc_A7
  {3, 0x48, 0x8B, 0x05}, GAP(4),            // mov     rax, cs:__cthread_init_routine
  {3, 0x48, 0x8B, 0x00},                    // mov     rax, [rax]
  {3, 0x48, 0x85, 0xC0},                    // test    rax, rax
  {2, 0x74, 0x02},                          // jz      short loc_B8
  {2, 0xFF, 0xD0},                          // call    rax

  // loc_B8
  {1, 0xE8}, GAP(4),                        // call    near ptr ___keymgr_dwarf2_register_sections
  {4, 0x48, 0x8D, 0x75, 0xD0},              // lea     rsi, [rbp+var_30]
  {3, 0x48, 0x8D, 0x3D}, GAP(4),            // lea     rdi, a__dyld_make_de ; "__dyld_make_delayed_module_initializer_"...
  {1, 0xE8}, GAP(4),                        // call    __dyld_func_lookup
  {3, 0xFF, 0x55, 0xD0},                    // call    [rbp+var_30]
  {4, 0x48, 0x8D, 0x75, 0xD8},              // lea     rsi, [rbp+var_28]
  {3, 0x48, 0x8D, 0x3D}, GAP(4),            // lea     rdi, a__dyld_mod_ter ; "__dyld_mod_term_funcs"
  {1, 0xE8}, GAP(4),                        // call    __dyld_func_lookup
  {4, 0x48, 0x8B, 0x7D, 0xD8},              // mov     rdi, [rbp+var_28]
  {3, 0x48, 0x85, 0xFF},                    // test    rdi, rdi
  {2, 0x74, 0x05},                          // jz      short loc_EE
  {1, 0xE8}, GAP(4),                        // call    near ptr _atexit

  // loc_EE
  {3, 0x48, 0x8B, 0x05}, GAP(4),            // mov     rax, cs:_errno
  {6, 0xC7, 0x00, 0x00, 0x00, 0x00, 0x00},  // mov     dword ptr [rax], 0
  {3, 0x4C, 0x89, 0xE9},                    // mov     rcx, r13
  {3, 0x48, 0x89, 0xDA},                    // mov     rdx, rbx
  {3, 0x4C, 0x89, 0xE6},                    // mov     rsi, r12
  {3, 0x44, 0x89, 0xF7},                    // mov     edi, r14d
  {1, 0xE8}, GAP(4),                        // call    near ptr _main
  {2, 0x89, 0xC7},                          // mov     edi, eax
  {1, 0xE8}, GAP(4),                        // call    near ptr _exit
};


//==================================
// SDK:10.5 DeployTarget:10.4
// MacOSX10.5.sdk/usr/lib/crt1.o
//==================================
static AsmFootPrint const SDK105Target104X86 =
{
  //start:
  {2, 0x6A, 0x00},                          // push    0
  {2, 0x89, 0xE5},                          // mov     ebp, esp
  {3, 0x83, 0xE4, 0xF0},                    // and     esp, 0FFFFFFF0h
  {3, 0x83, 0xEC, 0x10},                    // sub     esp, 10h
  {3, 0x8B, 0x5D, 0x04},                    // mov     ebx, [ebp+4]
  {4, 0x89, 0x5C, 0x24, 0x00},              // mov     [esp+14h+var_14], ebx
  {3, 0x8D, 0x4D, 0x08},                    // lea     ecx, [ebp+8]
  {4, 0x89, 0x4C, 0x24, 0x04},              // mov     [esp+14h+var_10], ecx
  {3, 0x83, 0xC3, 0x01},                    // add     ebx, 1
  {3, 0xC1, 0xE3, 0x02},                    // shl     ebx, 2
  {2, 0x01, 0xCB},                          // add     ebx, ecx
  {4, 0x89, 0x5C, 0x24, 0x08},              // mov     [esp+14h+var_C], ebx
  {5, 0xE8, 0x01, 0x00, 0x00, 0x00},        // call    __start
  {1, 0xF4},                                // hlt
  
  //__start:
  {1, 0x55},                                // push    ebp
  {2, 0x89, 0xE5},                          // mov     ebp, esp
  {1, 0x57},                                // push    edi
  {1, 0x56},                                // push    esi
  {1, 0x53},                                // push    ebx
  {3, 0x83, 0xEC, 0x2C},                    // sub     esp, 2Ch
  {3, 0x8B, 0x75, 0x0C},                    // mov     esi, [ebp+arg_4]
  {3, 0x8B, 0x45, 0x08},                    // mov     eax, [ebp+arg_0]
  {3, 0x8B, 0x5D, 0x10},                    // mov     ebx, [ebp+arg_8]
  {2, 0x89, 0x35}, GAP(4),                  // mov     ds:_NXArgv, esi
  {1, 0xA3}, GAP(4),                        // mov     ds:_NXArgc, eax
  {2, 0x89, 0x1D}, GAP(4),                  // mov     ds:_environ, ebx
  {2, 0x8B, 0x0E},                          // mov     ecx, [esi]
  {2, 0x85, 0xC9},                          // test    ecx, ecx
  {3, 0x8D, 0x41, 0x01},                    // lea     eax, [ecx+1]
  {2, 0x75, 0x0E},                          // jnz     short loc_64
  {1, 0xB9}, GAP(4),                        // mov     ecx, offset byte_118
  {2, 0xEB, 0x0F},                          // jmp     short loc_6C
  // ---------------------------------------------------------------------------
  
  //loc_5D:
  {3, 0x80, 0xFA, 0x2F},                    // cmp     dl, 2Fh ; '/'
  {3, 0x0F, 0x44, 0xC8},                    // cmovz   ecx, eax
  {1, 0x40},                                // inc     eax
  
  //loc_64:
  {4, 0x0F, 0xB6, 0x50, 0xFF},              // movzx   edx, byte ptr [eax-1]
  {2, 0x84, 0xD2},                          // test    dl, dl
  {2, 0x75, 0xF1},                          // jnz     short loc_5D
  
  //loc_6C:
  {2, 0x89, 0xD8},                          // mov     eax, ebx
  {2, 0x89, 0x0D}, GAP(4),                  // mov     ds:___progname, ecx
  {2, 0xEB, 0x03},                          // jmp     short loc_79
  // ---------------------------------------------------------------------------
  
  //loc_76:
  {3, 0x83, 0xC0, 0x04},                    // add     eax, 4
  
  //loc_79:
  {2, 0x8B, 0x10},                          // mov     edx, [eax]
  {2, 0x85, 0xD2},                          // test    edx, edx
  {2, 0x75, 0xF7},                          // jnz     short loc_76
  {3, 0x8D, 0x78, 0x04},                    // lea     edi, [eax+4]
  {1, 0xA1}, GAP(4),                        // mov     eax, ds:_mach_init_routine_ptr
  {2, 0x8B, 0x00},                          // mov     eax, [eax]
  {2, 0x85, 0xC0},                          // test    eax, eax
  {2, 0x74, 0x02},                          // jz      short loc_8F
  {2, 0xFF, 0xD0},                          // call    eax
  
  //loc_8F:
  {1, 0xA1}, GAP(4),                        // mov     eax, ds:__cthread_init_routine_ptr
  {2, 0x8B, 0x00},                          // mov     eax, [eax]
  {2, 0x85, 0xC0},                          // test    eax, eax
  {2, 0x74, 0x02},                          // jz      short loc_9C
  {2, 0xFF, 0xD0},                          // call    eax
  
  //loc_9C:
  {1, 0xE8}, GAP(4),                        // call    near ptr ___keymgr_dwarf2_register_sections
  {3, 0x8D, 0x45, 0xE0},                    // lea     eax, [ebp+var_20]
  {4, 0x89, 0x44, 0x24, 0x04},              // mov     [esp+4], eax
  {3, 0xC7, 0x04, 0x24}, GAP(4),            // mov     dword ptr [esp], offset a__dyld_make_de ; "__dyld_make_delayed_module_initializer_"...
  {1, 0xE8}, GAP(4),                        // call    __dyld_func_lookup
  {3, 0xFF, 0x55, 0xE0},                    // call    [ebp+var_20]
  {3, 0x8D, 0x45, 0xE4},                    // lea     eax, [ebp+var_1C]
  {4, 0x89, 0x44, 0x24, 0x04},              // mov     [esp+4], eax
  {3, 0xC7, 0x04, 0x24}, GAP(4),            // mov     dword ptr [esp], offset a__dyld_mod_ter ; "__dyld_mod_term_funcs"
  {1, 0xE8}, GAP(4),                        // call    __dyld_func_lookup
  {3, 0x8B, 0x45, 0xE4},                    // mov     eax, [ebp+var_1C]
  {2, 0x85, 0xC0},                          // test    eax, eax
  {2, 0x74, 0x08},                          // jz      short loc_D9
  {3, 0x89, 0x04, 0x24},                    // mov     [esp], eax      ; void (*)(void)
  {1, 0xE8}, GAP(4),                        // call    near ptr _atexit
  
  //loc_D9:
  {1, 0xA1}, GAP(4),                        // mov     eax, ds:_errno_ptr
  {6, 0xC7, 0x00, 0x00, 0x00, 0x00, 0x00},  // mov     dword ptr [eax], 0
  {3, 0x8B, 0x45, 0x08},                    // mov     eax, [ebp+arg_0]
  {4, 0x89, 0x7C, 0x24, 0x0C},              // mov     [esp+0Ch], edi
  {4, 0x89, 0x5C, 0x24, 0x08},              // mov     [esp+8], ebx
  {4, 0x89, 0x74, 0x24, 0x04},              // mov     [esp+4], esi
  {3, 0x89, 0x04, 0x24},                    // mov     [esp], eax
  {1, 0xE8}, GAP(4),                        // call    near ptr _main
  {3, 0x89, 0x04, 0x24},                    // mov     [esp], eax      ; int
  {1, 0xE8}, GAP(4),                        // call    near ptr _exit
};

static AsmFootPrint const SDK105Target104X86_64 =
{
  //start:
  {2, 0x6A, 0x00},                          // push    0
  {3, 0x48, 0x89, 0xE5},                    // mov     rbp, rsp
  {4, 0x48, 0x83, 0xE4, 0xF0},              // and     rsp, 0FFFFFFFFFFFFFFF0h
  {4, 0x48, 0x8B, 0x7D, 0x08},              // mov     rdi, [rbp+8]
  {4, 0x48, 0x8D, 0x75, 0x10},              // lea     rsi, [rbp+10h]
  {2, 0x89, 0xFA},                          // mov     edx, edi
  {3, 0x83, 0xC2, 0x01},                    // add     edx, 1
  {3, 0xC1, 0xE2, 0x03},                    // shl     edx, 3
  {3, 0x48, 0x01, 0xF2},                    // add     rdx, rsi
  {5, 0xE8, 0x01, 0x00, 0x00, 0x00},        // call    __start
  {1, 0xF4},                                // hlt

  // __start
  {1, 0x55},                                // push    rbp
  {3, 0x48, 0x89, 0xE5},                    // mov     rbp, rsp
  {2, 0x41, 0x56},                          // push    r14
  {3, 0x41, 0x89, 0xFE},                    // mov     r14d, edi
  {2, 0x41, 0x55},                          // push    r13
  {2, 0x41, 0x54},                          // push    r12
  {3, 0x49, 0x89, 0xF4},                    // mov     r12, rsi
  {1, 0x53},                                // push    rbx
  {3, 0x48, 0x89, 0xD3},                    // mov     rbx, rdx
  {4, 0x48, 0x83, 0xEC, 0x10},              // sub     rsp, 10h
  {2, 0x89, 0x3D}, GAP(4),                  // mov     cs:_NXArgc, edi
  {3, 0x48, 0x89, 0x35}, GAP(4),            // mov     cs:_NXArgv, rsi
  {3, 0x48, 0x89, 0x15}, GAP(4),            // mov     cs:_environ, rdx
  {3, 0x48, 0x8B, 0x0E},                    // mov     rcx, [rsi]
  {3, 0x48, 0x85, 0xC9},                    // test    rcx, rcx
  {4, 0x48, 0x8D, 0x41, 0x01},              // lea     rax, [rcx+1]
  {2, 0x75, 0x13},                          // jnz     short loc_6D
  {3, 0x48, 0x8D, 0x0D}, GAP(4),            // lea     rcx, LC0
  {2, 0xEB, 0x12},                          // jmp     short loc_75
  // ---------------------------------------------------------------------------

  // loc_63
  {3, 0x80, 0xFA, 0x2F},                    // cmp     dl, 2Fh ; '/'
  {4, 0x48, 0x0F, 0x44, 0xC8},              // cmovz   rcx, rax
  {3, 0x48, 0xFF, 0xC0},                    // inc     rax

  // loc_6D
  {4, 0x0F, 0xB6, 0x50, 0xFF},              // movzx   edx, byte ptr [rax-1]
  {2, 0x84, 0xD2},                          // test    dl, dl
  {2, 0x75, 0xEE},                          // jnz     short loc_63

  // loc_75
  {3, 0x48, 0x89, 0xD8},                    // mov     rax, rbx
  {3, 0x48, 0x89, 0x0D}, GAP(4),            // mov     cs:___progname, rcx
  {2, 0xEB, 0x04},                          // jmp     short loc_85
  // ---------------------------------------------------------------------------

  // loc_81
  {4, 0x48, 0x83, 0xC0, 0x08},              // add     rax, 8

  // loc_85
  {4, 0x48, 0x83, 0x38, 0x00},              // cmp     qword ptr [rax], 0
  {2, 0x75, 0xF6},                          // jnz     short loc_81
  {4, 0x4C, 0x8D, 0x68, 0x08},              // lea     r13, [rax+8]
  {3, 0x48, 0x8B, 0x05}, GAP(4),            // mov     rax, cs:_mach_init_routine
  {3, 0x48, 0x8B, 0x00},                    // mov     rax, [rax]
  {3, 0x48, 0x85, 0xC0},                    // test    rax, rax
  {2, 0x74, 0x02},                          // jz      short loc_A0
  {2, 0xFF, 0xD0},                          // call    rax

  // loc_A0
  {3, 0x48, 0x8B, 0x05}, GAP(4),            // mov     rax, cs:__cthread_init_routine
  {3, 0x48, 0x8B, 0x00},                    // mov     rax, [rax]
  {3, 0x48, 0x85, 0xC0},                    // test    rax, rax
  {2, 0x74, 0x02},                          // jz      short loc_B1
  {2, 0xFF, 0xD0},                          // call    rax

  // loc_B1
  {1, 0xE8}, GAP(4),                        // call    near ptr ___keymgr_dwarf2_register_sections
  {4, 0x48, 0x8D, 0x75, 0xD0},              // lea     rsi, [rbp+var_30]
  {3, 0x48, 0x8D, 0x3D}, GAP(4),            // lea     rdi, LC1        ; "__dyld_make_delayed_module_initializer_"...
  {1, 0xE8}, GAP(4),                        // call    __dyld_func_lookup
  {3, 0xFF, 0x55, 0xD0},                    // call    [rbp+var_30]
  {3, 0x48, 0x8D, 0x3D}, GAP(4),            // lea     rdi, LC2        ; "__dyld_mod_term_funcs"
  {4, 0x48, 0x8D, 0x75, 0xD8},              // lea     rsi, [rbp+var_28]
  {1, 0xE8}, GAP(4),                        // call    __dyld_func_lookup
  {4, 0x48, 0x8B, 0x7D, 0xD8},              // mov     rdi, [rbp+var_28]
  {3, 0x48, 0x85, 0xFF},                    // test    rdi, rdi
  {2, 0x74, 0x05},                          // jz      short loc_E7
  {1, 0xE8}, GAP(4),                        // call    near ptr _atexit

  // loc_E7
  {3, 0x48, 0x8B, 0x05}, GAP(4),            // mov     rax, cs:_errno
  {3, 0x44, 0x89, 0xF7},                    // mov     edi, r14d
  {3, 0x4C, 0x89, 0xE9},                    // mov     rcx, r13
  {3, 0x48, 0x89, 0xDA},                    // mov     rdx, rbx
  {3, 0x4C, 0x89, 0xE6},                    // mov     rsi, r12
  {6, 0xC7, 0x00, 0x00, 0x00, 0x00, 0x00},  // mov     dword ptr [rax], 0
  {1, 0xE8}, GAP(4),                        // call    near ptr _main
  {2, 0x89, 0xC7},                          // mov     edi, eax
  {1, 0xE8}, GAP(4),                        // call    near ptr _exit
};



//==================================
// SDK:10.6 DeployTarget:10.4
// MacOSX10.6.sdk/usr/lib/crt1.o
//==================================
static AsmFootPrint const SDK106Target104X86 =
{
  //start:
  {2, 0x6A, 0x00},                          // push    0
  {2, 0x89, 0xE5},                          // mov     ebp, esp
  {3, 0x83, 0xE4, 0xF0},                    // and     esp, 0FFFFFFF0h
  {3, 0x83, 0xEC, 0x10},                    // sub     esp, 10h
  {3, 0x8B, 0x5D, 0x04},                    // mov     ebx, [ebp+4]
  {3, 0x89, 0x1C, 0x24},                    // mov     [esp+14h+var_14], ebx
  {3, 0x8D, 0x4D, 0x08},                    // lea     ecx, [ebp+8]
  {4, 0x89, 0x4C, 0x24, 0x04},              // mov     [esp+14h+var_10], ecx
  {3, 0x83, 0xC3, 0x01},                    // add     ebx, 1
  {3, 0xC1, 0xE3, 0x02},                    // shl     ebx, 2
  {2, 0x01, 0xCB},                          // add     ebx, ecx
  {4, 0x89, 0x5C, 0x24, 0x08},              // mov     [esp+14h+var_C], ebx
  {5, 0xE8, 0x01, 0x00, 0x00, 0x00},        // call    __start
  {1, 0xF4},                                // hlt
  
  //__start:
  {1, 0x55},                                // push    ebp
  {2, 0x89, 0xE5},                          // mov     ebp, esp
  {1, 0x57},                                // push    edi
  {1, 0x56},                                // push    esi
  {1, 0x53},                                // push    ebx
  {3, 0x83, 0xEC, 0x2C},                    // sub     esp, 2Ch
  {3, 0x8B, 0x7D, 0x0C},                    // mov     edi, [ebp+arg_4]
  {3, 0x8B, 0x75, 0x10},                    // mov     esi, [ebp+arg_8]
  {3, 0x8B, 0x45, 0x08},                    // mov     eax, [ebp+arg_0]
  {1, 0xA3}, GAP(4),                        // mov     ds:_NXArgc, eax
  {2, 0x89, 0x3D}, GAP(4),                  // mov     ds:_NXArgv, edi
  {2, 0x89, 0x35}, GAP(4),                  // mov     ds:_environ, esi
  {2, 0x8B, 0x0F},                          // mov     ecx, [edi]
  {3, 0x8D, 0x51, 0x01},                    // lea     edx, [ecx+1]
  {2, 0x85, 0xC9},                          // test    ecx, ecx
  {2, 0x75, 0x0D},                          // jnz     short loc_62
  {1, 0xB9}, GAP(4),                        // mov     ecx, offset byte_118
  {2, 0xEB, 0x0E},                          // jmp     short loc_6A
  // ---------------------------------------------------------------------------
  
  //loc_5C:
  {2, 0x3C, 0x2F},                          // cmp     al, 2Fh ; '/'
  {3, 0x0F, 0x44, 0xCA},                    // cmovz   ecx, edx
  {1, 0x42},                                // inc     edx
  
  //loc_62:
  {4, 0x0F, 0xB6, 0x42, 0xFF},              // movzx   eax, byte ptr [edx-1]
  {2, 0x84, 0xC0},                          // test    al, al
  {2, 0x75, 0xF2},                          // jnz     short loc_5C
  
  //loc_6A:
  {2, 0x89, 0x0D}, GAP(4),                  // mov     ds:___progname, ecx
  {2, 0x89, 0xF3},                          // mov     ebx, esi
  {2, 0xEB, 0x03},                          // jmp     short loc_77
  // ---------------------------------------------------------------------------
  
  //loc_74:
  {3, 0x83, 0xC3, 0x04},                    // add     ebx, 4
  
  //loc_77:
  {2, 0x8B, 0x03},                          // mov     eax, [ebx]
  {2, 0x85, 0xC0},                          // test    eax, eax
  {2, 0x75, 0xF7},                          // jnz     short loc_74
  {1, 0xA1}, GAP(4),                        // mov     eax, ds:_mach_init_routine_ptr
  {2, 0x8B, 0x00},                          // mov     eax, [eax]
  {2, 0x85, 0xC0},                          // test    eax, eax
  {2, 0x74, 0x02},                          // jz      short loc_8A
  {2, 0xFF, 0xD0},                          // call    eax
  
  //loc_8A:
  {1, 0xA1}, GAP(4),                        // mov     eax, ds:__cthread_init_routine_ptr
  {2, 0x8B, 0x00},                          // mov     eax, [eax]
  {2, 0x85, 0xC0},                          // test    eax, eax
  {2, 0x74, 0x02},                          // jz      short loc_97
  {2, 0xFF, 0xD0},                          // call    eax
  
  //loc_97:
  {1, 0xE8}, GAP(4),                        // call    near ptr ___keymgr_dwarf2_register_sections
  {3, 0x8D, 0x45, 0xE0},                    // lea     eax, [ebp+var_20]
  {4, 0x89, 0x44, 0x24, 0x04},              // mov     [esp+4], eax
  {3, 0xC7, 0x04, 0x24}, GAP(4),            // mov     dword ptr [esp], offset a__dyld_make_de ; "__dyld_make_delayed_module_initializer_"...
  {1, 0xE8}, GAP(4),                        // call    __dyld_func_lookup
  {3, 0xFF, 0x55, 0xE0},                    // call    [ebp+var_20]
  {3, 0x8D, 0x45, 0xE4},                    // lea     eax, [ebp+var_1C]
  {4, 0x89, 0x44, 0x24, 0x04},              // mov     [esp+4], eax
  {3, 0xC7, 0x04, 0x24}, GAP(4),            // mov     dword ptr [esp], offset a__dyld_mod_ter ; "__dyld_mod_term_funcs"
  {1, 0xE8}, GAP(4),                        // call    __dyld_func_lookup
  {3, 0x8B, 0x45, 0xE4},                    // mov     eax, [ebp+var_1C]
  {2, 0x85, 0xC0},                          // test    eax, eax
  {2, 0x74, 0x08},                          // jz      short loc_D4
  {3, 0x89, 0x04, 0x24},                    // mov     [esp], eax      ; void (*)(void)
  {1, 0xE8}, GAP(4),                        // call    near ptr _atexit
  
  //loc_D4:
  {1, 0xA1}, GAP(4),                        // mov     eax, ds:_errno_ptr
  {6, 0xC7, 0x00, 0x00, 0x00, 0x00, 0x00},  // mov     dword ptr [eax], 0
  {3, 0x8D, 0x43, 0x04},                    // lea     eax, [ebx+4]
  {4, 0x89, 0x44, 0x24, 0x0C},              // mov     [esp+0Ch], eax
  {4, 0x89, 0x74, 0x24, 0x08},              // mov     [esp+8], esi
  {4, 0x89, 0x7C, 0x24, 0x04},              // mov     [esp+4], edi
  {3, 0x8B, 0x45, 0x08},                    // mov     eax, [ebp+arg_0]
  {3, 0x89, 0x04, 0x24},                    // mov     [esp], eax
  {1, 0xE8}, GAP(4),                        // call    near ptr _main
  {3, 0x89, 0x04, 0x24},                    // mov     [esp], eax      ; int
  {1, 0xE8}, GAP(4),                        // call    near ptr _exit
};

static AsmFootPrint const SDK106Target104X86_64 =
{
  //start:
  {2, 0x6A, 0x00},                          // push    0
  {3, 0x48, 0x89, 0xE5},                    // mov     rbp, rsp
  {4, 0x48, 0x83, 0xE4, 0xF0},              // and     rsp, 0FFFFFFFFFFFFFFF0h
  {4, 0x48, 0x8B, 0x7D, 0x08},              // mov     rdi, [rbp+8]
  {4, 0x48, 0x8D, 0x75, 0x10},              // lea     rsi, [rbp+10h]
  {2, 0x89, 0xFA},                          // mov     edx, edi
  {3, 0x83, 0xC2, 0x01},                    // add     edx, 1
  {3, 0xC1, 0xE2, 0x03},                    // shl     edx, 3
  {3, 0x48, 0x01, 0xF2},                    // add     rdx, rsi
  {5, 0xE8, 0x01, 0x00, 0x00, 0x00},        // call    __start
  {1, 0xF4},                                // hlt

  // __start
  {1, 0x55},                                // push    rbp
  {3, 0x48, 0x89, 0xE5},                    // mov     rbp, rsp
  {2, 0x41, 0x56},                          // push    r14
  {2, 0x41, 0x55},                          // push    r13
  {2, 0x41, 0x54},                          // push    r12
  {1, 0x53},                                // push    rbx
  {4, 0x48, 0x83, 0xEC, 0x10},              // sub     rsp, 10h
  {3, 0x41, 0x89, 0xFE},                    // mov     r14d, edi
  {3, 0x49, 0x89, 0xF5},                    // mov     r13, rsi
  {3, 0x49, 0x89, 0xD4},                    // mov     r12, rdx
  {2, 0x89, 0x3D}, GAP(4),                  // mov     cs:_NXArgc, edi
  {3, 0x48, 0x89, 0x35}, GAP(4),            // mov     cs:_NXArgv, rsi
  {3, 0x48, 0x89, 0x15}, GAP(4),            // mov     cs:_environ, rdx
  {3, 0x48, 0x8B, 0x0E},                    // mov     rcx, [rsi]
  {4, 0x48, 0x8D, 0x41, 0x01},              // lea     rax, [rcx+1]
  {3, 0x48, 0x85, 0xC9},                    // test    rcx, rcx
  {2, 0x75, 0x13},                          // jnz     short loc_6D
  {3, 0x48, 0x8D, 0x0D}, GAP(4),            // lea     rcx, LC0
  {2, 0xEB, 0x12},                          // jmp     short loc_75
  // ---------------------------------------------------------------------------

  // loc_63
  {3, 0x80, 0xFA, 0x2F},                    // cmp     dl, 2Fh ; '/'
  {4, 0x48, 0x0F, 0x44, 0xC8},              // cmovz   rcx, rax
  {3, 0x48, 0xFF, 0xC0},                    // inc     rax

  // loc_6D
  {4, 0x0F, 0xB6, 0x50, 0xFF},              // movzx   edx, byte ptr [rax-1]
  {2, 0x84, 0xD2},                          // test    dl, dl
  {2, 0x75, 0xEE},                          // jnz     short loc_63

  // loc_75
  {3, 0x48, 0x89, 0x0D}, GAP(4),            // mov     cs:___progname, rcx
  {3, 0x4C, 0x89, 0xE3},                    // mov     rbx, r12
  {2, 0xEB, 0x04},                          // jmp     short loc_85
  // ---------------------------------------------------------------------------

  // loc_81
  {4, 0x48, 0x83, 0xC3, 0x08},              // add     rbx, 8

  // loc_85
  {4, 0x48, 0x83, 0x3B, 0x00},              // cmp     qword ptr [rbx], 0
  {2, 0x75, 0xF6},                          // jnz     short loc_81
  {3, 0x48, 0x8B, 0x05}, GAP(4),            // mov     rax, cs:_mach_init_routine
  {3, 0x48, 0x8B, 0x00},                    // mov     rax, [rax]
  {3, 0x48, 0x85, 0xC0},                    // test    rax, rax
  {2, 0x74, 0x02},                          // jz      short loc_9C
  {2, 0xFF, 0xD0},                          // call    rax

  // loc_9C
  {3, 0x48, 0x8B, 0x05}, GAP(4),            // mov     rax, cs:__cthread_init_routine
  {3, 0x48, 0x8B, 0x00},                    // mov     rax, [rax]
  {3, 0x48, 0x85, 0xC0},                    // test    rax, rax
  {2, 0x74, 0x02},                          // jz      short loc_AD
  {2, 0xFF, 0xD0},                          // call    rax

  // loc_AD
  {1, 0xE8}, GAP(4),                        // call    near ptr ___keymgr_dwarf2_register_sections
  {4, 0x48, 0x8D, 0x75, 0xD0},              // lea     rsi, [rbp+var_30]
  {3, 0x48, 0x8D, 0x3D}, GAP(4),            // lea     rdi, LC1        ; "__dyld_make_delayed_module_initializer_"...
  {1, 0xE8}, GAP(4),                        // call    __dyld_func_lookup
  {3, 0xFF, 0x55, 0xD0},                    // call    [rbp+var_30]
  {4, 0x48, 0x8D, 0x75, 0xD8},              // lea     rsi, [rbp+var_28]
  {3, 0x48, 0x8D, 0x3D}, GAP(4),            // lea     rdi, LC2        ; "__dyld_mod_term_funcs"
  {1, 0xE8}, GAP(4),                        // call    __dyld_func_lookup
  {4, 0x48, 0x8B, 0x7D, 0xD8},              // mov     rdi, [rbp+var_28]
  {3, 0x48, 0x85, 0xFF},                    // test    rdi, rdi
  {2, 0x74, 0x05},                          // jz      short loc_E3
  {1, 0xE8}, GAP(4),                        // call    near ptr _atexit

  // loc_E3
  {3, 0x48, 0x8B, 0x05}, GAP(4),            // mov     rax, cs:_errno
  {6, 0xC7, 0x00, 0x00, 0x00, 0x00, 0x00},  // mov     dword ptr [rax], 0
  {4, 0x48, 0x8D, 0x4B, 0x08},              // lea     rcx, [rbx+8]
  {3, 0x4C, 0x89, 0xE2},                    // mov     rdx, r12
  {3, 0x4C, 0x89, 0xEE},                    // mov     rsi, r13
  {3, 0x44, 0x89, 0xF7},                    // mov     edi, r14d
  {1, 0xE8}, GAP(4),                        // call    near ptr _main
  {2, 0x89, 0xC7},                          // mov     edi, eax
  {1, 0xE8}, GAP(4),                        // call    near ptr _exit
};

//==================================
// SDK:10.5 DeployTarget:10.5
// MacOSX10.5.sdk/usr/lib/crt1.10.5.o
//==================================
static AsmFootPrint const SDK105Target105X86 =
{
  //start:
  {2, 0x6A, 0x00},                          // push    0
  {2, 0x89, 0xE5},                          // mov     ebp, esp
  {3, 0x83, 0xE4, 0xF0},                    // and     esp, 0FFFFFFF0h
  {3, 0x83, 0xEC, 0x10},                    // sub     esp, 10h
  {3, 0x8B, 0x5D, 0x04},                    // mov     ebx, [ebp+4]
  {4, 0x89, 0x5C, 0x24, 0x00},              // mov     [esp+14h+var_14], ebx
  {3, 0x8D, 0x4D, 0x08},                    // lea     ecx, [ebp+8]
  {4, 0x89, 0x4C, 0x24, 0x04},              // mov     [esp+14h+var_10], ecx
  {3, 0x83, 0xC3, 0x01},                    // add     ebx, 1
  {3, 0xC1, 0xE3, 0x02},                    // shl     ebx, 2
  {2, 0x01, 0xCB},                          // add     ebx, ecx
  {4, 0x89, 0x5C, 0x24, 0x08},              // mov     [esp+14h+var_C], ebx
  
  //loc_24:
  {2, 0x8B, 0x03},                          // mov     eax, [ebx]
  {3, 0x83, 0xC3, 0x04},                    // add     ebx, 4
  {2, 0x85, 0xC0},                          // test    eax, eax
  {2, 0x75, 0xF7},                          // jnz     short loc_24
  {4, 0x89, 0x5C, 0x24, 0x0C},              // mov     [esp+14h+var_8], ebx
  {1, 0xE8}, GAP(4),                        // call    near ptr _main
  {4, 0x89, 0x44, 0x24, 0x00},              // mov     [esp+14h+var_14], eax ; int
  {1, 0xE8}, GAP(4),                        // call    near ptr _exit
};

static AsmFootPrint const SDK105Target105X86_64 =
{
  //start:
  {2, 0x6A, 0x00},                          // push    0
  {3, 0x48, 0x89, 0xE5},                    // mov     rbp, rsp
  {4, 0x48, 0x83, 0xE4, 0xF0},              // and     rsp, 0FFFFFFFFFFFFFFF0h
  {4, 0x48, 0x8B, 0x7D, 0x08},              // mov     rdi, [rbp+8]
  {4, 0x48, 0x8D, 0x75, 0x10},              // lea     rsi, [rbp+10h]
  {2, 0x89, 0xFA},                          // mov     edx, edi
  {3, 0x83, 0xC2, 0x01},                    // add     edx, 1
  {3, 0xC1, 0xE2, 0x03},                    // shl     edx, 3
  {3, 0x48, 0x01, 0xF2},                    // add     rdx, rsi
  {3, 0x48, 0x89, 0xD1},                    // mov     rcx, rdx
  {2, 0xEB, 0x04},                          // jmp     short loc_25
  // ---------------------------------------------------------------------------

  // loc_21
  {4, 0x48, 0x83, 0xC1, 0x08},              // add     rcx, 8

  // loc_25
  {4, 0x48, 0x83, 0x39, 0x00},              // cmp     qword ptr [rcx], 0
  {2, 0x75, 0xF6},                          // jnz     short loc_21
  {4, 0x48, 0x83, 0xC1, 0x08},              // add     rcx, 8
  {1, 0xE8}, GAP(4),                        // call    near ptr _main
  {2, 0x89, 0xC7},                          // mov     edi, eax
  {1, 0xE8}, GAP(4),                        // call    near ptr _exit  
};
  
//==================================
// SDK:10.6 DeployTarget:10.5
// MacOSX10.6.sdk/usr/lib/crt1.10.5.o
//==================================
static AsmFootPrint const SDK106Target105X86 =
{
  //start:
  {2, 0x6A, 0x00},                          // push    0
  {2, 0x89, 0xE5},                          // mov     ebp, esp
  {3, 0x83, 0xE4, 0xF0},                    // and     esp, 0FFFFFFF0h
  {3, 0x83, 0xEC, 0x10},                    // sub     esp, 10h
  {3, 0x8B, 0x5D, 0x04},                    // mov     ebx, [ebp+4]
  {3, 0x89, 0x1C, 0x24},                    // mov     [esp+14h+var_14], ebx
  {3, 0x8D, 0x4D, 0x08},                    // lea     ecx, [ebp+8]
  {4, 0x89, 0x4C, 0x24, 0x04},              // mov     [esp+14h+var_10], ecx
  {3, 0x83, 0xC3, 0x01},                    // add     ebx, 1
  {3, 0xC1, 0xE3, 0x02},                    // shl     ebx, 2
  {2, 0x01, 0xCB},                          // add     ebx, ecx
  {4, 0x89, 0x5C, 0x24, 0x08},              // mov     [esp+14h+var_C], ebx
  
  //loc_23:
  {2, 0x8B, 0x03},                          // mov     eax, [ebx]
  {3, 0x83, 0xC3,0x04},                     // add     ebx, 4
  {2, 0x85, 0xC0},                          // test    eax, eax
  {2, 0x75, 0xF7},                          // jnz     short loc_23
  {4, 0x89, 0x5C, 0x24, 0x0C},              // mov     [esp+14h+var_8], ebx
  {1, 0xE8}, GAP(4),                        // call    near ptr _main
  {3, 0x89, 0x04, 0x24},                    // mov     [esp+14h+var_14], eax ; int
  {1, 0xE8}, GAP(4),                        // call    near ptr _exit
};

static AsmFootPrint const SDK106Target104X86v2 =
{
  //start:
  {2,  0x6A, 0x00},                         // push    0
  {2,  0x89, 0xE5},                         // mov     ebp, esp
  {3,  0x83, 0xE4, 0xF0},                   // and     esp, 0FFFFFFF0h
  {3,  0x83, 0xEC, 0x10},                   // sub     esp, 10h
  {3,  0x8B, 0x5D, 0x04},                   // mov     ebx, [ebp+4]
  {3,  0x89, 0x1C, 0x24},                   // mov     [esp+14h+var_14], ebx
  {3,  0x8D, 0x4D, 0x08},                   // lea     ecx, [ebp+8]
  {4,  0x89, 0x4C, 0x24, 0x04},             // mov     [esp+14h+var_10], ecx
  {3,  0x83, 0xC3, 0x01},                   // add     ebx, 1
  {3,  0xC1, 0xE3, 0x02},                   // shl     ebx, 2
  {2,  0x01, 0xCB},                         // add     ebx, ecx
  {4,  0x89, 0x5C, 0x24, 0x08},             // mov     [esp+14h+var_C], ebx
  {5,  0xE8, 0x01, 0x00, 0x00, 0x00},       // call    __start
  {1,  0xF4},                               // hlt
  
  //__start:
  {1,  0x55},                               // push    ebp
  {2,  0x89, 0xE5},                         // mov     ebp, esp
  {1,  0x53},                               // push    ebx
  {1,  0x57},                               // push    edi
  {1,  0x56},                               // push    esi
  {3,  0x83, 0xEC, 0x1C},                   // sub     esp, 1Ch
  {3,  0x8B, 0x45, 0x08},                   // mov     eax, [ebp+arg_0]
  {1,  0xA3}, GAP(4),                       // mov     ds:_NXArgc, eax
  {3,  0x8B, 0x7D, 0x0C},                   // mov     edi, [ebp+arg_4]
  {2,  0x89, 0x3D}, GAP(4),                 // mov     ds:_NXArgv, edi
  {3,  0x8B, 0x75, 0x10},                   // mov     esi, [ebp+arg_8]
  {2,  0x89, 0x35}, GAP(4),                 // mov     ds:_environ, esi
  {2,  0x8B, 0x07},                         // mov     eax, [edi]
  {1,  0xB9}, GAP(4),                       // mov     ecx, offset byte_199DAE
  {2,  0x85, 0xC0},                         // test    eax, eax
  {2,  0x74, 0x18},                         // jz      short loc_2B8F
  {2,  0xEB, 0x02},                         // jmp     short loc_2B7B
  
  // loc_2B79
  {2,  0x89, 0xC8},                         // mov     eax, ecx
  
  // loc_2B7B:
  {3,  0x8D, 0x48, 0x01},                   // lea     ecx, [eax+1]
  {2,  0xEB, 0x06},                         // jmp     short loc_2B86
  
  // loc_2BB0:
  {3,  0x80, 0xFA, 0x2F},                   // cmp     dl, 2Fh
  {2,  0x74, 0xF4},                         // jz      short loc_2B79
  {1,  0x41},                               // inc     ecx
  
  // loc_2B86:
  {3,  0x8A, 0x51, 0xFF},                   // mov     dl, [ecx-1]
  {2,  0x84, 0xD2},                         // test    dl, dl
  {2,  0x75, 0xF3},                         // jnz     short loc_2B80
  {2,  0x89, 0xC1},                         // mov     ecx, eax
  
  // loc_2B8F:
  {2,  0x89, 0x0D}, GAP(4),                 // mov     ds:___progname, ecx
  {2,  0x89, 0xF3},                         // mov     ebx, esi
  
  // loc_2B97:
  {3,  0x83, 0x3B, 0x00},                   // cmp     dword ptr [ebx], 0
  {3,  0x8D, 0x5B, 0x04},                   // lea     ebx, [ebx+4]
  {2,  0x75, 0xF8},                         // jnz     short loc_2B97
  {1,  0xA1}, GAP(4),                       // mov     eax, ds:_mach_init_routine_ptr
  {2,  0x8B, 0x00},                         // mov     eax, [eax]
  {2,  0x85, 0xC0},                         // test    eax, eax
  {2,  0x74, 0x02},                         // jz      short loc_2BAC
  {2,  0xFF, 0xD0},                         // call    eax
  
  // loc_2BAC:
  {1,  0xA1}, GAP(4),                       // mov     eax, ds:__cthread_init_routine_ptr
  {2,  0x8B, 0x00},                         // mov     eax, [eax]
  {2,  0x85, 0xC0},                         // test    eax, eax
  {2,  0x74, 0x02},                         // jz      short loc_2BB9
  {2,  0xFF, 0xD0},                         // call    eax
  
  // loc_2BB9:
  {1,  0xE8}, GAP(4),                       // call    ___keymgr_dwarf2_register_sections
  {3,  0x8D, 0x45, 0xEC},                   // lea     eax, [ebp+var_14]
  {4,  0x89, 0x44, 0x24, 0x04},             // mov     [esp+4], eax
  {3,  0xC7, 0x04, 0x24}, GAP(4),           // mov     dword ptr [esp], offset a__dyld_make_de ; "__dyld_make_delayed_module_initializer_"...
  {1,  0xE8}, GAP(4),                       // call    __dyld_func_lookup
  {3,  0xFF, 0x55, 0xEC},                   // call    [ebp+var_14]
  {3,  0x8D, 0x45, 0xF0},                   // lea     eax, [ebp+var_10]
  {4,  0x89, 0x44, 0x24, 0x04},             // mov     [esp+4], eax
  {3,  0xC7, 0x04, 0x24}, GAP(4),           // mov     dword ptr [esp], offset a__dyld_mod_ter ; "__dyld_mod_term_funcs"
  {1,  0xE8}, GAP(4),                       // call    __dyld_func_lookup
  {3,  0x8B, 0x45, 0xF0},                   // mov     eax, [ebp+var_10]
  {2,  0x85, 0xC0},                         // test    eax, eax
  {2,  0x74, 0x08},                         // jz      short loc_2BF6
  {3,  0x89, 0x04, 0x24},                   // mov     [esp], eax      ; void (*)(void)
  {1,  0xE8}, GAP(4),                       // call    _atexit
  
  // loc_2BF6:
  {1,  0xA1}, GAP(4),                       // mov     eax, ds:_errno_ptr
  {6,  0xC7, 0x00, 0x00, 0x00, 0x00, 0x00}, // mov     dword ptr [eax], 0
  {4,  0x89, 0x5C, 0x24, 0x0C},             // mov     [esp+0Ch], ebx
  {4,  0x89, 0x74, 0x24, 0x08},             // mov     [esp+8], esi
  {4,  0x89, 0x7C, 0x24, 0x04},             // mov     [esp+4], edi
  {3,  0x8B, 0x45, 0x08},                   // mov     eax, [ebp+arg_0]
  {3,  0x89, 0x04, 0x24},                   // mov     [esp], eax
  {1,  0xE8}, GAP(4),                       // call    _main
  {3,  0x89, 0x04, 0x24},                   // mov     [esp], eax      ; int
  {1,  0xE8}, GAP(4),                       // call    _exit
};


// SDK106Target105X86_64 == SDK105Target105X86_64;

//==================================
// SDK:10.6 DeployTarget:10.6
// MacOSX10.6.sdk/usr/lib/crt1.10.6.o
//==================================

//SDK106Target106X86 == SDK106Target105X86;
//SDK106Target106X86_64 == SDK106Target105X86_64;

//==============================================================================
@implementation MachOLayout (CRTFootPrints)

//------------------------------------------------------------------------------
- (bool) matchAsmAtOffset:(uint32_t)offset 
             asmFootPrint:(const AsmFootPrint)footprint 
                lineCount:(NSUInteger)lineCount
{
  uint8_t const * data = ((uint8_t *)[dataController.fileData bytes]) + offset;
  
  for (NSUInteger i = 0; i < lineCount; ++i)
  {
    uint8_t const * asmEntry = footprint[i];
    int size = asmEntry[0];
    
    // is it a gap to skip ?
    if (size == 0)
    {
      size = asmEntry[1];
    }
    else if (memcmp(data, asmEntry + 1, size))
    {
      return false;
    }
    data += size;
  }
  
  return true;
}

//------------------------------------------------------------------------------
- (void) determineRuntimeVersion
{
  if (entryPoint == 0)
  {
    return; // not an executable, no entry point, or cannot detect
  }
  
  // find file offset of the entry point
  uint32_t offset = [self is64bit] == NO 
                      ? [self RVAToFileOffset:entryPoint] 
                      : [self RVA64ToFileOffset:entryPoint];
  
  NSLog(@"%@: file offset of OEP: 0x%X", self, offset);
  
  uint32_t dataLength = [dataController.fileData length];
  
  if (offset >= dataLength)
  {
    return;
  }
  
  // test against footprints
  if ([self is64bit] == NO)
  {
    if (MATCHASM(SDK104Target104X86v1))
    {
      NSLog(@"SDK104Target104X86v1 matched");
      rootNode.caption = [rootNode.caption stringByAppendingString:@" [SDK10.4 Target10.4]"];
      return;
    }
    else if (MATCHASM(SDK104Target104X86v2))
    {
      NSLog(@"SDK104Target104X86v2 matched");
      rootNode.caption = [rootNode.caption stringByAppendingString:@" [SDK10.4 Target10.4]"];
      return;
    }
    else if (MATCHASM(SDK104Target104X86v3))
    {
      NSLog(@"SDK104Target104X86v3 matched");
      rootNode.caption = [rootNode.caption stringByAppendingString:@" [SDK10.4 Target10.4]"];
      return;
    }
    else if (MATCHASM(SDK104Target104X86v4))
    {
      NSLog(@"SDK104Target104X86v4 matched");
      rootNode.caption = [rootNode.caption stringByAppendingString:@" [SDK10.4 Target10.4]"];
      return;
    }
    else if (MATCHASM(SDK105Target104X86))
    {
      NSLog(@"SDK105Target104X86 matched");
      rootNode.caption = [rootNode.caption stringByAppendingString:@" [SDK10.5 Target10.4]"];
      return;
    }
    else if (MATCHASM(SDK105Target105X86))
    {
      NSLog(@"SDK105Target105X86 matched");
      rootNode.caption = [rootNode.caption stringByAppendingString:@" [SDK10.5 Target10.5]"];
      return;
    }
    else if (MATCHASM(SDK106Target104X86) || MATCHASM(SDK106Target104X86v2))
    {
      NSLog(@"SDK106Target104X86 matched");
      rootNode.caption = [rootNode.caption stringByAppendingString:@" [SDK10.6 Target10.4]"];
      return;
    }
    else if (MATCHASM(SDK106Target105X86))
    {
      NSLog(@"SDK106Target105X86 matched");
      
      for (CommandVector::const_iterator cmdIter = commands.begin(); cmdIter != commands.end(); ++cmdIter)
      {
        struct load_command const * load_command = (struct load_command const *)(*cmdIter);
        if (load_command->cmd == LC_DYLD_INFO_ONLY)
        {
          rootNode.caption = [rootNode.caption stringByAppendingString:@" [SDK10.6 Target10.6]"]; 
          NSLog(@"LC_DYLD_INFO_ONLY  ==> target10.6");
          return;
        }
      }
      rootNode.caption = [rootNode.caption stringByAppendingString:@" [SDK10.6 Target10.5]"];
      return;
    }
  }
  else
  {
    if (MATCHASM(SDK104Target104X86_64))
    {
      NSLog(@"SDK104Target104X86_64 matched");
      rootNode.caption = [rootNode.caption stringByAppendingString:@" [SDK10.4 Target10.4]"];
      return;
    }
    else if (MATCHASM(SDK105Target104X86_64))
    {
      NSLog(@"SDK105Target104X86_64 matched");
      rootNode.caption = [rootNode.caption stringByAppendingString:@" [SDK10.5 Target10.4]"];
      return;
    }
    else if (MATCHASM(SDK106Target104X86_64))
    {
      NSLog(@"SDK106Target104X86_64 matched");
      rootNode.caption = [rootNode.caption stringByAppendingString:@" [SDK10.6 Target10.4]"];
      return;
    }
    else if (MATCHASM(SDK105Target105X86_64))
    {
      NSLog(@"SDK105Target105X86_64 matched");
      
      for (CommandVector::const_iterator cmdIter = commands.begin(); cmdIter != commands.end(); ++cmdIter)
      {
        struct load_command const * load_command = (struct load_command const *)(*cmdIter);
        if (load_command->cmd == LC_DYLD_INFO_ONLY)
        {
          NSLog(@"LC_DYLD_INFO_ONLY  ==> target10.6");
          rootNode.caption = [rootNode.caption stringByAppendingString:@" [SDK10.6]"]; 
          return;
        }
      }
      rootNode.caption = [rootNode.caption stringByAppendingString:@" [SDK10.5]"];
      return;
    }
    
  }
  
}
//------------------------------------------------------------------------------

@end

