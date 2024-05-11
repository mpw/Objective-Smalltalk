//
//  MPWARMObjectCodeGeneratorExternalTestsMachO.m
//  ObjSTNative
//
//  Created by Marcel Weiher on 11.05.24.
//

#import "MPWARMObjectCodeGeneratorExternalTestsMachO.h"
#import "MPWMachOWriter.h"
#import "MPWMachOReader.h"
#import "MPWJittableData.h"

@implementation MPWARMObjectCodeGeneratorExternalTestsMachO

@end


#import <MPWFoundation/DebugMacros.h>

@implementation MPWARMObjectCodeGeneratorExternalTestsMachO(testing) 

+(void)testGenerateMachOWithCallToExternalFunction
{
    MPWMachOWriter *writer = [MPWMachOWriter stream];
    STARMObjectCodeGenerator *g=[self stream];
    g.symbolWriter = writer;
    g.relocationWriter = writer.textSectionWriter;
    [g generateFunctionNamed:@"_theFunction" body:^(STARMObjectCodeGenerator *gen) {
        [g generateCallToExternalFunctionNamed:@"_other"];
    }];
    [writer addTextSectionData:(NSData*)[g target]];
    //    NSLog(@"before write file");
    [writer writeFile];
    //    NSLog(@"after write file");
    NSData *macho=[writer data];
    [macho writeToFile:@"/tmp/theFunction-calls-other.o" atomically:YES];
    MPWMachOReader *reader=[[[MPWMachOReader alloc] initWithData:macho] autorelease];
    INTEXPECT( [[reader textSection] offsetOfRelocEntryAt:0], 12,@"location of call to _other");
    IDEXPECT( [[reader textSection] nameOfRelocEntryAt:0], @"_other",@"name of call to _other");
}

+(void)testGenerateMachOWithMessageSend
{
    MPWMachOWriter *writer = [MPWMachOWriter stream];
    STARMObjectCodeGenerator *g=[self stream];
    g.symbolWriter = writer;
    g.relocationWriter = writer.textSectionWriter;
    [g generateFunctionNamed:@"_lengthOfString" body:^(STARMObjectCodeGenerator *gen) {
        [g generateMessageSendToSelector:@"length"];
    }];
    [writer addTextSectionData:(NSData*)[g target]];
    [writer writeFile];
    NSData *macho=[writer data];
    //    [macho writeToFile:@"/tmp/theFunction-sends-length.o" atomically:YES];
    MPWMachOReader *reader=[[[MPWMachOReader alloc] initWithData:macho] autorelease];
    INTEXPECT( [[reader textSection] offsetOfRelocEntryAt:0], 12,@"location of call to _other");
    IDEXPECT( [[reader textSection] nameOfRelocEntryAt:0], @"_objc_msgSend$length",@"name of msg send");
}

+(void)testGenerateMessageSendAndComputation
{
    STARMObjectCodeGenerator *g=[self stream];
    [g generateFunctionNamed:@"_lengthOfString" body:^(STARMObjectCodeGenerator *gen) {
        [g generateMessageSendToSelector:@"hash"];
        [gen generateAddDest:0 source:0 immediate:200];
    }];
    MPWJittableData *d=[g generatedCode];
    NSData *code=[NSData dataWithBytes:d.bytes length:d.length];
    [code writeToFile:@"/tmp/hashPlus200.code" atomically:YES];
}

+(NSArray*)testSelectors
{
    return @[
        @"testGenerateMachOWithCallToExternalFunction",
        @"testGenerateMachOWithMessageSend",
        @"testGenerateMessageSendAndComputation",
        //       @"testJITMessageSendAndComputation",
        //       @"testJITLengthOfPassedStringPlus3",
        //    @"testEmbeddedPointerGenerationOverRange",

    ];
}

@end
