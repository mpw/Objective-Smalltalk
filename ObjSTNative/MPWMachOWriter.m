//
//  MPWMachOWriter.m
//  ObjSTNative
//
//  Created by Marcel Weiher on 14.09.22.
//

#import "MPWMachOWriter.h"
#import <mach-o/loader.h>

@implementation MPWMachOWriter


-(void)writeHeader
{
    struct mach_header_64 header={};
    header.magic = MH_MAGIC_64;
    header.cputype = CPU_TYPE_ARM64;
    header.filetype = MH_OBJECT;
    [self appendBytes:&header length:sizeof header];
}

-(NSData*)data
{
    return (NSData*)self.target;
}

@end


#import <MPWFoundation/DebugMacros.h>
#import "MPWMachOReader.h"

@implementation MPWMachOWriter(testing) 

+(void)testCanWriteHeader
{
    MPWMachOWriter *writer = [self stream];
    [writer writeHeader];
    
    NSData *macho=[writer data];
    [macho writeToFile:@"/tmp/generated.o" atomically:YES];
    MPWMachOReader *reader = [[[MPWMachOReader alloc] initWithData:macho] autorelease];
	EXPECTTRUE([reader isHeaderValid], @"header valid");
    INTEXPECT([reader cputype],CPU_TYPE_ARM64,@"cputype");
    INTEXPECT([reader filetype],MH_OBJECT,@"filetype");
}

+(NSArray*)testSelectors
{
   return @[
			@"testCanWriteHeader",
			];
}

@end
