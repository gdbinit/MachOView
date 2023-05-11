//
//  thread_status.h
//  MachOView
//
//  Created by reverser on 10/05/2023.
//

/*
 * Copyright (c) 1999-2010 Apple Inc.  All Rights Reserved.
 *
 * @APPLE_LICENSE_HEADER_START@
 *
 * This file contains Original Code and/or Modifications of Original Code
 * as defined in and that are subject to the Apple Public Source License
 * Version 2.0 (the 'License'). You may not use this file except in
 * compliance with the License. Please obtain a copy of the License at
 * http://www.opensource.apple.com/apsl/ and read it before using this
 * file.
 *
 * The Original Code and all software distributed under the License are
 * distributed on an 'AS IS' basis, WITHOUT WARRANTY OF ANY KIND, EITHER
 * EXPRESS OR IMPLIED, AND APPLE HEREBY DISCLAIMS ALL SUCH WARRANTIES,
 * INCLUDING WITHOUT LIMITATION, ANY WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE, QUIET ENJOYMENT OR NON-INFRINGEMENT.
 * Please see the License for the specific language governing rights and
 * limitations under the License.
 *
 * @APPLE_LICENSE_HEADER_END@
 */

#ifndef thread_status_h
#define thread_status_h

#include <stdint.h>

#define __STRUCT_X86_THREAD_STATE32      struct ___darwin_i386_thread_state
__STRUCT_X86_THREAD_STATE32
{
    unsigned int    eax;
    unsigned int    ebx;
    unsigned int    ecx;
    unsigned int    edx;
    unsigned int    edi;
    unsigned int    esi;
    unsigned int    ebp;
    unsigned int    esp;
    unsigned int    ss;
    unsigned int    eflags;
    unsigned int    eip;
    unsigned int    cs;
    unsigned int    ds;
    unsigned int    es;
    unsigned int    fs;
    unsigned int    gs;
};

#define __STRUCT_X86_THREAD_STATE64      struct ___darwin_x86_thread_state64
__STRUCT_X86_THREAD_STATE64
{
    uint64_t    rax;
    uint64_t    rbx;
    uint64_t    rcx;
    uint64_t    rdx;
    uint64_t    rdi;
    uint64_t    rsi;
    uint64_t    rbp;
    uint64_t    rsp;
    uint64_t    r8;
    uint64_t    r9;
    uint64_t    r10;
    uint64_t    r11;
    uint64_t    r12;
    uint64_t    r13;
    uint64_t    r14;
    uint64_t    r15;
    uint64_t    rip;
    uint64_t    rflags;
    uint64_t    cs;
    uint64_t    fs;
    uint64_t    gs;
};

/*
 * THREAD_STATE_FLAVOR_LIST 0
 *      these are the supported flavors
 */
#define _x86_THREAD_STATE32              1
#define _x86_FLOAT_STATE32               2
#define _x86_EXCEPTION_STATE32           3
#define _x86_THREAD_STATE64              4
#define _x86_FLOAT_STATE64               5
#define _x86_EXCEPTION_STATE64           6
#define _x86_THREAD_STATE                7
#define _x86_FLOAT_STATE                 8
#define _x86_EXCEPTION_STATE             9
#define _x86_DEBUG_STATE32               10
#define _x86_DEBUG_STATE64               11
#define _x86_DEBUG_STATE                 12
#define _x86_THREAD_STATE_NONE           13
/* 14 and 15 are used for the internal x86_SAVED_STATE flavours */
/* Arrange for flavors to take sequential values, 32-bit, 64-bit, non-specific */
#define _x86_AVX_STATE32                 16
#define _x86_AVX_STATE64                 (_x86_AVX_STATE32 + 1)
#define _x86_AVX_STATE                   (_x86_AVX_STATE32 + 2)
#define _x86_AVX512_STATE32              19
#define _x86_AVX512_STATE64              (_x86_AVX512_STATE32 + 1)
#define _x86_AVX512_STATE                (_x86_AVX512_STATE32 + 2)
#define _x86_PAGEIN_STATE                22
#define _x86_THREAD_FULL_STATE64         23
#define _x86_INSTRUCTION_STATE           24
#define _x86_LAST_BRANCH_STATE           25

struct _x86_state_hdr {
    uint32_t        flavor;
    uint32_t        count;
};
typedef struct _x86_state_hdr _x86_state_hdr_t;

typedef __STRUCT_X86_THREAD_STATE32 _x86_thread_state32_t;
#define x86_THREAD_STATE32_COUNT        ((mach_msg_type_number_t) \
    ( sizeof (x86_thread_state32_t) / sizeof (int) ))

typedef __STRUCT_X86_THREAD_STATE64 _x86_thread_state64_t;
#define x86_THREAD_STATE64_COUNT        ((mach_msg_type_number_t) \
    ( sizeof (x86_thread_state64_t) / sizeof (int) ))

/*
 * Combined thread, float and exception states
 */
struct _x86_thread_state {
    _x86_state_hdr_t                 tsh;
    union {
        _x86_thread_state32_t        ts32;
        _x86_thread_state64_t        ts64;
    } uts;
};

typedef struct _x86_thread_state _x86_thread_state_t;
#define _x86_THREAD_STATE_COUNT  ((mach_msg_type_number_t) \
            ( sizeof (x86_thread_state_t) / sizeof (int) ))

#endif /* thread_status_h */
