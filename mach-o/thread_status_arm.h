//
//  thread_status_arm.h
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

#ifndef thread_status_arm_h
#define thread_status_arm_h

#include <stdint.h>

#define __STRUCT_ARM_THREAD_STATE struct ___darwin_arm_thread_state
__STRUCT_ARM_THREAD_STATE
{
    uint32_t    r[13]; /* General purpose register r0-r12 */
    uint32_t    sp;    /* Stack pointer r13 */
    uint32_t    lr;    /* Link register r14 */
    uint32_t    pc;    /* Program counter r15 */
    uint32_t    cpsr;  /* Current program status register */
};

#define __STRUCT_ARM_THREAD_STATE64 struct ___darwin_arm_thread_state64
__STRUCT_ARM_THREAD_STATE64
{
    uint64_t    x[29]; /* General purpose registers x0-x28 */
    uint64_t    fp;    /* Frame pointer x29 */
    uint64_t    lr;    /* Link register x30 */
    uint64_t    sp;    /* Stack pointer x31 */
    uint64_t    pc;    /* Program counter */
    uint32_t    cpsr;  /* Current program status register */
    uint32_t    pad;   /* Same size for 32-bit or 64-bit clients */
};

/*
 *  Flavors
 */

#define _ARM_THREAD_STATE         1
#define _ARM_UNIFIED_THREAD_STATE ARM_THREAD_STATE
#define _ARM_VFP_STATE            2
#define _ARM_EXCEPTION_STATE      3
#define _ARM_DEBUG_STATE          4 /* pre-armv8 */
#define _ARM_THREAD_STATE_NONE        5
#define _ARM_THREAD_STATE64       6
#define _ARM_EXCEPTION_STATE64    7
//      ARM_THREAD_STATE_LAST    8 /* legacy */
#define _ARM_THREAD_STATE32       9
#define _ARM_DEBUG_STATE32        14
#define _ARM_DEBUG_STATE64        15
#define _ARM_NEON_STATE           16
#define _ARM_NEON_STATE64         17
#define _ARM_CPMU_STATE64         18
#define _ARM_PAGEIN_STATE         27

#ifndef ARM_STATE_FLAVOR_IS_OTHER_VALID
#define ARM_STATE_FLAVOR_IS_OTHER_VALID(_flavor_) 0
#endif

struct _arm_state_hdr {
    uint32_t flavor;
    uint32_t count;
};
typedef struct _arm_state_hdr _arm_state_hdr_t;

typedef __STRUCT_ARM_THREAD_STATE   _arm_thread_state_t;
typedef __STRUCT_ARM_THREAD_STATE   _arm_thread_state32_t;
typedef __STRUCT_ARM_THREAD_STATE64 _arm_thread_state64_t;

struct _arm_unified_thread_state {
    _arm_state_hdr_t ash;
    union {
        _arm_thread_state32_t ts32;
        _arm_thread_state64_t ts64;
    } uts;
};
typedef struct _arm_unified_thread_state _arm_unified_thread_state_t;

#define ARM_THREAD_STATE_COUNT ((mach_msg_type_number_t) \
    (sizeof (arm_thread_state_t)/sizeof(uint32_t)))
#define ARM_THREAD_STATE32_COUNT ((mach_msg_type_number_t) \
    (sizeof (arm_thread_state32_t)/sizeof(uint32_t)))
#define ARM_THREAD_STATE64_COUNT ((mach_msg_type_number_t) \
    (sizeof (arm_thread_state64_t)/sizeof(uint32_t)))
#define ARM_UNIFIED_THREAD_STATE_COUNT ((mach_msg_type_number_t) \
    (sizeof (arm_unified_thread_state_t)/sizeof(uint32_t)))

#endif /* thread_status_arm_h */
