//
//  MPWMachOWriter.m
//  ObjSTNative
//
//  Created by Marcel Weiher on 14.09.22.
//
// http://www.cilinder.be/docs/next/NeXTStep/3.3/nd/DevTools/14_MachO/MachO.htmld/index.html
//

#import "MPWMachOWriter.h"
#import <mach-o/loader.h>

@interface MPWMachOWriter()

@property (nonatomic, assign) int numLoadCommands;
@property (nonatomic, assign) int cputype;
@property (nonatomic, assign) int filetype;
@property (nonatomic, assign) int loadCommandSize;

@end


@implementation MPWMachOWriter

-(instancetype)initWithTarget:(id)aTarget
{
    self=[super initWithTarget:aTarget];
    self.cputype = CPU_TYPE_ARM64;
    self.filetype = MH_OBJECT;
    return self;
}


-(void)writeHeader
{
    struct mach_header_64 header={};
    header.magic = MH_MAGIC_64;
    header.cputype = self.cputype;
    header.filetype = self.filetype;
    header.ncmds = self.numLoadCommands;
    header.sizeofcmds = self.loadCommandSize;
    [self appendBytes:&header length:sizeof header];
}

-(void)writeSymboltableLoadCommand
{
    struct symtab_command symtab={};
    symtab.cmd = LC_SYMTAB;
    symtab.cmdsize = sizeof symtab;
    symtab.nsyms = self.globalSymbols.count;
    [self appendBytes:&symtab length:sizeof symtab];
    
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
    MPWMachOReader *reader = [[[MPWMachOReader alloc] initWithData:macho] autorelease];
    EXPECTTRUE([reader isHeaderValid], @"header valid");
    INTEXPECT([reader cputype],CPU_TYPE_ARM64,@"cputype");
    INTEXPECT([reader filetype],MH_OBJECT,@"filetype");
    INTEXPECT([reader numLoadCommands],0,@"number load commands");
}

+(void)testCanWriteGlobalSymboltable
{
    MPWMachOWriter *writer = [self stream];
    NSData *macho=[writer data];
    writer.globalSymbols = @{ @"_add": @(10) };
    writer.numLoadCommands = 1;
    writer.loadCommandSize = sizeof(struct symtab_command);
    [writer writeHeader];
    [writer writeSymboltableLoadCommand];
    
    MPWMachOReader *reader = [[[MPWMachOReader alloc] initWithData:macho] autorelease];

    EXPECTTRUE([reader isHeaderValid],@"valid header");
    INTEXPECT([reader numLoadCommands],1,@"number of load commands");
    INTEXPECT([reader numSymbols],1,@"number of symbols");
}

+(NSArray*)testSelectors
{
   return @[
       @"testCanWriteHeader",
       @"testCanWriteGlobalSymboltable",
			];
}

@end
