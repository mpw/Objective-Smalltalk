//
//  MPWMachOLinker.m
//  ObjSTNative
//
//  Internal linker: transforms object file data into a loadable dylib
//

#import "MPWMachOLinker.h"
#import "MPWMachOWriter.h"
#import "MPWMachOWriter+Private.h"
#import "MPWMachOSectionWriter.h"
#import "MPWMachODylibWriter.h"

@implementation MPWMachOLinker

-(NSData*)linkToDylibWithInstallName:(NSString*)installName
                          fromWriter:(MPWMachOWriter*)objectWriter
{
    return [self linkToDylibWithInstallName:installName
                           sectionWriters:[objectWriter activeSectionWriters]
                             symbolWriter:objectWriter];
}

-(NSData*)linkToDylibWithInstallName:(NSString*)installName
                     sectionWriters:(NSArray<MPWMachOSectionWriter*>*)sections
                       symbolWriter:(MPWMachOWriter*)symbolSource
{
    // For now, just create a basic dylib with the __TEXT sections
    // TODO: Handle __DATA sections
    // TODO: Convert relocations to bind opcodes

    MPWMachODylibWriter *dylibWriter = [MPWMachODylibWriter stream];
    dylibWriter.installName = installName;

    // Copy __TEXT section data
    for (MPWMachOSectionWriter *section in sections) {
        if ([section.segname isEqualToString:@"__TEXT"]) {
            if ([section.sectname isEqualToString:@"__text"]) {
                // Main code section - copy to the dylib writer's text section
                [dylibWriter addTextSectionData:[section data]];
            }
            // TODO: Handle other __TEXT sections like __objc_methname, __cstring, etc.
        }
    }

    // TODO: Handle __DATA sections
    // TODO: Export symbols
    // TODO: Create bind opcodes for external symbol references

    [dylibWriter writeFile];
    return [dylibWriter data];
}

@end


#import <MPWFoundation/DebugMacros.h>

@implementation MPWMachOLinker(testing)

+(void)testLinkEmptyWriterProducesDylib
{
    MPWMachOWriter *objectWriter = [MPWMachOWriter stream];

    // Add minimal code
    unsigned char retCode[] = { 0x00, 0x00, 0x80, 0xD2, 0xC0, 0x03, 0x5F, 0xD6 };  // mov x0, #0; ret
    [objectWriter.textSectionWriter declareGlobalTextSymbol:@"_testFunc"];
    [objectWriter addTextSectionData:[NSData dataWithBytes:retCode length:sizeof(retCode)]];

    MPWMachOLinker *linker = [[[self alloc] init] autorelease];
    NSData *dylib = [linker linkToDylibWithInstallName:@"@rpath/test.dylib" fromWriter:objectWriter];

    EXPECTNOTNIL(dylib, @"should produce dylib data");
    EXPECTTRUE(dylib.length > 0, @"dylib should have content");

    // Verify it's a valid Mach-O dylib header
    const uint32_t *magic = dylib.bytes;
    INTEXPECT(*magic, 0xFEEDFACF, @"should have 64-bit Mach-O magic");
}

+(NSArray*)testSelectors
{
    return @[
        @"testLinkEmptyWriterProducesDylib",
    ];
}

@end
