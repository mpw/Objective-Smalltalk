//
//  MPWMachOSection.m
//  ObjSTNative
//
//  Created by Marcel Weiher on 04.10.22.
//

#import "MPWMachOSection.h"
#import <mach-o/loader.h>
#import <mach-o/reloc.h>
#import "MPWMachOReader.h"

@interface MPWMachOSection()

@property (nonatomic, strong) NSData *machoData;
@property (nonatomic, weak) MPWMachOReader *reader;

@end

@implementation MPWMachOSection
{
    const struct section_64 *sectionHeader;
}

-(instancetype)initWithSectionHeader:(const void*)headerptr inMacho:(MPWMachOReader*)newReader
{
    self=[super init];
    if ( self ) {
        sectionHeader=headerptr;
        self.machoData = newReader.data;
        self.reader = newReader;
    }
    return self;
}

-(NSData*)sectionData
{
    return [self.machoData subdataWithRange:NSMakeRange(sectionHeader->offset,sectionHeader->size)];
}

-(int)numRelocEntries
{
    return sectionHeader->nreloc;
}

-(int)relocEntryOffset
{
    return sectionHeader->reloff;
}

-(struct relocation_info)relocEntryAt:(int)i
{
    const struct relocation_info *reloc=[self.machoData bytes] + [self relocEntryOffset];
    return reloc[i];
}

-(NSString*)nameOfRelocEntryAt:(int)i
{
    struct relocation_info reloc=[self relocEntryAt:0];
    return [self.reader symbolNameAt:reloc.r_symbolnum];
}

-(long)offsetOfRelocEntryAt:(int)i
{
    struct relocation_info reloc=[self relocEntryAt:0];
    return reloc.r_address;
}

-(int)typeOfRelocEntryAt:(int)i
{
    struct relocation_info reloc=[self relocEntryAt:0];
    return reloc.r_type;
}



-(bool)isExternalRelocEntryAt:(int)i
{
    struct relocation_info reloc=[self relocEntryAt:0];
    return reloc.r_extern != 0;
}


-(void)dealloc
{
    [_machoData release];
    [super dealloc];
}

@end


#import <MPWFoundation/DebugMacros.h>

@implementation MPWMachOSection(testing) 

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
