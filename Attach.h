/*
 *  Attach.h
 *  MachOView
 *
 *  Created by fG! on 08/09/13.
 *  reverser@put.as
 *
 */

#ifndef machoview_Attach_h
#define machoview_Attach_h

#include <mach/mach.h>
#include <mach/mach_vm.h>
#include <mach/vm_map.h>
#include <mach-o/loader.h>

int64_t get_image_size(mach_vm_address_t address, pid_t pid, uint64_t *vmaddr_slide);
kern_return_t find_main_binary(pid_t pid, mach_vm_address_t *main_address);
kern_return_t dump_binary(mach_vm_address_t address, pid_t pid, uint8_t *buffer, uint64_t aslr_slide);

#endif
