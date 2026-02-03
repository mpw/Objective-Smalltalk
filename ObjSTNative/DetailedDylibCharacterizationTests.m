
#import "MPWBindOpcodeWriter.h"
#import "MPWMachODylibWriter.h"
#import "MPWMachOLinker.h"
#import "MPWMachOReader.h"
#import "MPWMachOSection.h"
#import "MPWMachOSegment.h"
#import "STNativeCompiler.h"
#import <MPWFoundation/MPWFoundation.h>
#import <dlfcn.h>
#import <mach-o/loader.h>

@interface DetailedDylibCharacterizationTests : NSObject
@end

@implementation DetailedDylibCharacterizationTests

+ (void)testCompareBindAndRebaseOpcodesForSimpleClass {
  // 1. Define Source
  NSString *className = @"SimpleTestClass";
  NSString *source = [NSString
      stringWithFormat:@"class %@ : NSObject { -value { 42. } }", className];

  // 2. Generate Object File (In-Memory) using STNativeCompiler
  STNativeCompiler *compiler = [STNativeCompiler compiler];
  STClassDefinition *theClass = [compiler compile:source];
  [compiler compileClassToMachoO:theClass];
  MPWMachOWriter *objectWriter = (MPWMachOWriter *)compiler.writer;
  EXPECTNOTNIL(objectWriter, @"object writer");

  // 3. Generate Reference Dylib (External Linker)
  NSString *tempDir = NSTemporaryDirectory();
  NSString *objectPath = [tempDir
      stringByAppendingPathComponent:[NSString
                                         stringWithFormat:@"%@.o", className]];
  [objectWriter.data writeToFile:objectPath atomically:YES];

  NSString *refDylibPath = [tempDir
      stringByAppendingPathComponent:[NSString stringWithFormat:@"%@_ref.dylib",
                                                                className]];

  [compiler linkObjects:@[ className ]
        toSharedLibrary:[NSString stringWithFormat:@"%@_ref.dylib", className]
                  inDir:tempDir
         withFrameworks:@[
           @"MPWFoundation", @"Foundation", @"ObjectiveSmalltalk"
         ]];

  NSData *refDylibData = [NSData dataWithContentsOfFile:refDylibPath];
  EXPECTNOTNIL(refDylibData, @"reference dylib data");
  MPWMachOReader *refReader =
      [[MPWMachOReader alloc] initWithData:refDylibData];

  // 4. Generate Candidate Dylib (Internal Linker)
  MPWMachOLinker *linker = [[MPWMachOLinker alloc] init];
  NSData *candDylibData = [linker
      linkToDylibWithInstallName:[NSString stringWithFormat:@"@rpath/%@.dylib",
                                                            className]
                      fromWriter:objectWriter];
  EXPECTNOTNIL(candDylibData, @"candidate dylib data");
  MPWMachOReader *candReader =
      [[MPWMachOReader alloc] initWithData:candDylibData];

  // 5. Structural Characterization of Reference

  // Modern load commands in reference
  EXPECTNOTNIL([refReader loadCommandOfTypeIfPresent:LC_DYLD_CHAINED_FIXUPS],
               @"reference has chained fixups");

  // Segment layout
  MPWMachOSegment *refText = [refReader segmentObjectNamed:@"__TEXT"];
  EXPECTNOTNIL(refText, @"ref __TEXT");
  INTEXPECT(refText.vmaddr, 0, @"ref __TEXT vmaddr");

  MPWMachOSegment *refDataConst =
      [refReader segmentObjectNamed:@"__DATA_CONST"];
  EXPECTNOTNIL(refDataConst, @"ref __DATA_CONST");
  HEXEXPECT(refDataConst.vmaddr, 0x4000, @"ref __DATA_CONST vmaddr");

  MPWMachOSegment *refData = [refReader segmentObjectNamed:@"__DATA"];
  EXPECTNOTNIL(refData, @"ref __DATA");
  HEXEXPECT(refData.vmaddr, 0x8000, @"ref __DATA vmaddr");

  // Essential Sections
  EXPECTTRUE([self fileOffsetForSection:@"__text" inReader:refReader] >= 0,
             @"ref has __text");
  EXPECTTRUE([self fileOffsetForSection:@"__objc_imageinfo"
                               inReader:refReader] >= 0,
             @"ref has __objc_imageinfo");
  EXPECTTRUE([self fileOffsetForSection:@"__objc_classlist"
                               inReader:refReader] >= 0,
             @"ref has __objc_classlist");
  EXPECTTRUE([self fileOffsetForSection:@"__objc_data" inReader:refReader] >= 0,
             @"ref has __objc_data");

  // Exported Symbols
  NSString *objcClassName =
      [@"_OBJC_CLASS_$_" stringByAppendingString:className];
  EXPECTTRUE([refReader indexOfSymbolNamed:objcClassName] >= 0,
             @"ref has class symbol");

  // 6. Comparison with Candidate
  MPWMachOSegment *candText = [candReader segmentObjectNamed:@"__TEXT"];
  MPWMachOSegment *candDataConst =
      [candReader segmentObjectNamed:@"__DATA_CONST"];
  MPWMachOSegment *candData = [candReader segmentObjectNamed:@"__DATA"];

  EXPECTNOTNIL(candText, @"cand __TEXT");
  EXPECTNOTNIL(candDataConst, @"cand __DATA_CONST");
  EXPECTNOTNIL(candData, @"cand __DATA");

  if (candText && refText) {
    HEXEXPECT(candText.vmaddr, refText.vmaddr, @"__TEXT parity");
    HEXEXPECT(candText.vmsize, refText.vmsize, @"__TEXT size parity");
  }
  if (candDataConst && refDataConst) {
    HEXEXPECT(candDataConst.vmaddr, refDataConst.vmaddr,
              @"__DATA_CONST parity");
  }
  if (candData && refData) {
    HEXEXPECT(candData.vmaddr, refData.vmaddr, @"__DATA parity");
  }

  // Symbol parity
  EXPECTTRUE([candReader indexOfSymbolNamed:objcClassName] >= 0,
             @"cand has class symbol");

  // Internal pointer patching parity
  long candObjcDataOff = [self fileOffsetForSection:@"__objc_data"
                                           inReader:candReader];
  if (candObjcDataOff >= 0) {
    const uint64_t *candPtrs =
        (const uint64_t *)(candReader.data.bytes + candObjcDataOff);
    // Index 4: metaclass data (RO)
    // Index 9: class data (RO)
    HEXEXPECT(candPtrs[4] & 0xFFFFFFFFFFFFF000ULL, (uint64_t)candData.vmaddr,
              @"cand metaclass data patched");
    HEXEXPECT(candPtrs[9] & 0xFFFFFFFFFFFFF000ULL, (uint64_t)candData.vmaddr,
              @"cand class data patched");
  }
}

+ (long)fileOffsetForSection:(NSString *)sectname
                    inReader:(MPWMachOReader *)reader {
  if (!reader.data)
    return -1;
  for (MPWMachOSegment *seg in reader.allSegments) {
    MPWMachOSection *sect = [seg sectionNamed:sectname];
    if (sect) {
      return [sect offset];
    }
  }
  return -1;
}

+ (NSArray *)testSelectors {
  return @[ @"testCompareBindAndRebaseOpcodesForSimpleClass" ];
}

@end
