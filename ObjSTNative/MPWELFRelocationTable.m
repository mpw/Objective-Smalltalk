//
//  MPWELFRelocationTable.m
//  ObjSTNative
//
//  Created by Marcel Weiher on 29.06.24.
//

#import "elf.h"
#import "MPWELFRelocationTable.h"
#import "MPWELFReader.h"

@implementation MPWELFRelocationTable

-(Elf64_Rela*)relocationEntries
{
    return (Elf64_Rela*)([self.reader.elfData bytes] + [self sectionOffset]);
}



-(int)typeOfRelocEntryAt:(int)offset
{
    return (int)ELF64_R_TYPE([self relocationEntries][offset].r_info);
}


-(int)symbolIndexAtOffset:(int)offset
{
    return (int)ELF64_R_SYM([self relocationEntries][offset].r_info);
}

-(int)offsetOfRelocEntryAt:(int)offset
{
    return (int)[self relocationEntries][offset].r_offset;
}

@end


#import <MPWFoundation/DebugMacros.h>

@implementation MPWELFRelocationTable(testing) 

+(void)someTest
{
	EXPECTTRUE(false, @"implemented");
}

+(NSArray*)testSelectors
{
   return @[
//			@"someTest",
			];
}

@end
