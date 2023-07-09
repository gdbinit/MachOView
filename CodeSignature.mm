//
//  CodeSignature.m
//  MachOView
//
//  Created by ByteDance on 2023/7/9.
//

#import "CodeSignature.h"

uint32_t swap32(uint32_t num){
    return ((num>>24)&0xff) | // move byte 3 to byte 0
                        ((num<<8)&0xff0000) | // move byte 1 to byte 2
                        ((num>>8)&0xff00) | // move byte 2 to byte 1
                        ((num<<24)&0xff000000); // byte 0 to byte 3
    
}

NSString* parse_magic(uint32_t magic){
    
    switch(magic){
       case CSMAGIC_REQUIREMENT:
            return @"CSMAGIC_REQUIREMENT";
       case CSMAGIC_REQUIREMENTS:
            return @"CSMAGIC_REQUIREMENTS";
       case CSMAGIC_CODEDIRECTORY:
            return @"CSMAGIC_CODEDIRECTORY";
       case CSMAGIC_EMBEDDED_SIGNATURE:
            return @"CSMAGIC_EMBEDDED_SIGNATURE";
       case CSMAGIC_EMBEDDED_SIGNATURE_OLD:
           return @"CSMAGIC_EMBEDDED_SIGNATURE_OLD";
        case CSMAGIC_EMBEDDED_ENTITLEMENTS:
            return @"CSMAGIC_EMBEDDED_ENTITLEMENTS";
        case CSMAGIC_DETACHED_SIGNATURE:
            return @"CSMAGIC_DETACHED_SIGNATURE";
        case CSMAGIC_BLOBWRAPPER:
            return @"CSMAGIC_BLOBWRAPPER";
       default:
           return @"unknown";
    }
}
NSString* parse_type(uint32_t type){
    
    switch(type){
       case CSSLOT_CODEDIRECTORY:
            return @"CSSLOT_CODEDIRECTORY";
       case CSSLOT_INFOSLOT:
            return @"CSSLOT_INFOSLOT";
       case CSSLOT_REQUIREMENTS:
            return @"CSSLOT_REQUIREMENTS";
       case CSSLOT_RESOURCEDIR:
            return @"CSSLOT_RESOURCEDIR";
       case CSSLOT_APPLICATION:
           return @"CSSLOT_APPLICATION";
        case CSSLOT_ENTITLEMENTS:
            return @"CSSLOT_ENTITLEMENTS";
        case CSSLOT_SIGNATURESLOT:
            return @"CSSLOT_SIGNATURESLOT";
        case CSSLOT_ENTITLEMENTS_DER:
            return @"CSSLOT_ENTITLEMENTS_DER(0x07)";
        case CSSLOT_ALTERNATE_CODEDIRECTORIES:
            return @"CSSLOT_ALTERNATE_CODEDIRECTORIES";
       default:
           return @"unknown";
    }
}

// new CS_SuperBlob


