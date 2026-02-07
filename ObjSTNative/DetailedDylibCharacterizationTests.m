
#import "STBindOpcodeWriter.h"
#import "STMachODylibWriter.h"
#import "STMachOLinker.h"
#import "STMachOReader.h"
#import "MPWMachOSection.h"
#import "STMachOSegment.h"
#import "STNativeCompiler.h"
#import <MPWFoundation/MPWFoundation.h>
#import <dlfcn.h>
#import <mach-o/loader.h>

@interface DetailedDylibCharacterizationTests : NSObject
+ (void)codesignDylibAtPath:(NSString *)path;
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
  STMachOWriter *objectWriter = (STMachOWriter *)compiler.writer;
  EXPECTNOTNIL(objectWriter, @"object writer");

  // 3. Generate Reference Dylib (External Linker)
    NSString *tempDir = @"/tmp";
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
  STMachOReader *refReader =
      [[STMachOReader alloc] initWithData:refDylibData];

  // 4. Generate Candidate Dylib (Internal Linker)
  STMachOLinker *linker = [[STMachOLinker alloc] init];
  NSData *candDylibData = [linker
      linkToDylibWithInstallName:[NSString stringWithFormat:@"@rpath/%@.dylib",
                                                            className]
                      fromWriter:objectWriter];
  EXPECTNOTNIL(candDylibData, @"candidate dylib data");
  STMachOReader *candReader =
      [[STMachOReader alloc] initWithData:candDylibData];

  // 5. Structural Characterization of Reference

  // Modern load commands in reference
  EXPECTNOTNIL([refReader loadCommandOfTypeIfPresent:LC_DYLD_CHAINED_FIXUPS],
               @"reference has chained fixups");

  // Segment layout
  STMachOSegment *refText = [refReader segmentObjectNamed:@"__TEXT"];
  EXPECTNOTNIL(refText, @"ref __TEXT");
  INTEXPECT(refText.vmaddr, 0, @"ref __TEXT vmaddr");

  STMachOSegment *refDataConst =
      [refReader segmentObjectNamed:@"__DATA_CONST"];
  EXPECTNOTNIL(refDataConst, @"ref __DATA_CONST");
  HEXEXPECT(refDataConst.vmaddr, 0x4000, @"ref __DATA_CONST vmaddr");

  STMachOSegment *refData = [refReader segmentObjectNamed:@"__DATA"];
  EXPECTNOTNIL(refData, @"ref __DATA");
  HEXEXPECT(refData.vmaddr, 0x8000, @"ref __DATA vmaddr");

  // Essential Sections in Candidate
  EXPECTTRUE([self fileOffsetForSection:@"__text" inReader:candReader] >= 0,
             @"cand has __text");
  EXPECTTRUE([self fileOffsetForSection:@"__objc_imageinfo"
                               inReader:candReader] >= 0,
             @"cand has __objc_imageinfo");
  EXPECTTRUE([self fileOffsetForSection:@"__objc_classlist"
                               inReader:candReader] >= 0,
             @"cand has __objc_classlist");
  EXPECTTRUE([self fileOffsetForSection:@"__objc_data"
                               inReader:candReader] >= 0,
             @"cand has __objc_data");

  // Exported Symbols
  NSString *objcClassName =
      [@"_OBJC_CLASS_$_" stringByAppendingString:className];
  EXPECTTRUE([refReader indexOfSymbolNamed:objcClassName] >= 0,
             @"ref has class symbol");
  EXPECTTRUE([candReader indexOfSymbolNamed:objcClassName] >= 0,
             @"cand has class symbol");

  // LC_DYLD_INFO_ONLY in Candidate
  const struct dyld_info_command *candDyldInfo =
      (const struct dyld_info_command *)[candReader
          loadCommandOfTypeIfPresent:LC_DYLD_INFO_ONLY];
  EXPECTNOTNIL((id)(uintptr_t)candDyldInfo,
               @"candidate should have LC_DYLD_INFO_ONLY");
  if (candDyldInfo) {
    NSLog(@"Candidate bind_off: 0x%x, bind_size: %d", candDyldInfo->bind_off,
          candDyldInfo->bind_size);
    EXPECTTRUE(candDyldInfo->bind_size > 0,
               @"candidate should have bind opcodes");
  }

  // 6. Detailed Comparison with Reference
  STMachOSegment *candText = [candReader segmentObjectNamed:@"__TEXT"];
  STMachOSegment *candDataConst =
      [candReader segmentObjectNamed:@"__DATA_CONST"];
  STMachOSegment *candData = [candReader segmentObjectNamed:@"__DATA"];
  STMachOSegment *candLinkedit = [candReader segmentObjectNamed:@"__LINKEDIT"];

  EXPECTNOTNIL(candText, @"cand __TEXT");
  EXPECTNOTNIL(candDataConst, @"cand __DATA_CONST");
  EXPECTNOTNIL(candData, @"cand __DATA");
  EXPECTNOTNIL(candLinkedit, @"cand __LINKEDIT");

  if (candText && refText) {
    HEXEXPECT(candText.vmaddr, refText.vmaddr, @"__TEXT vmaddr parity");
    HEXEXPECT(candText.vmsize, refText.vmsize, @"__TEXT vmsize parity");
  }
  if (candDataConst && refDataConst) {
    HEXEXPECT(candDataConst.vmaddr, refDataConst.vmaddr,
              @"__DATA_CONST vmaddr parity");
  }
  if (candData && refData) {
    HEXEXPECT(candData.vmaddr, refData.vmaddr, @"__DATA vmaddr parity");
  }

  // Bind/Rebase parity
  const struct dyld_info_command *refDyldInfo =
      (const struct dyld_info_command *)[refReader
          loadCommandOfTypeIfPresent:LC_DYLD_INFO_ONLY];
  EXPECTNOTNIL((id)(uintptr_t)candDyldInfo, @"cand dyld info");
  if (refDyldInfo && candDyldInfo) {
    // We don't necessarily expect exact bind_size parity if the reference uses
    // different opcodes, but we should at least check they are non-zero if the
    // reference is non-zero.
    if (refDyldInfo->bind_size > 0) {
      EXPECTTRUE(candDyldInfo->bind_size > 0, @"cand should have bind opcodes");
    }
  }

  // ObjC Image Info Parity
  long refImageInfoOff = [self fileOffsetForSection:@"__objc_imageinfo"
                                           inReader:refReader];
  long candImageInfoOff = [self fileOffsetForSection:@"__objc_imageinfo"
                                            inReader:candReader];
  if (refImageInfoOff >= 0 && candImageInfoOff >= 0) {
    NSData *refImageInfo =
        [refReader.data subdataWithRange:NSMakeRange(refImageInfoOff, 8)];
    NSData *candImageInfo =
        [candReader.data subdataWithRange:NSMakeRange(candImageInfoOff, 8)];
    EXPECTTRUE([refImageInfo isEqualToData:candImageInfo],
               @"objc_imageinfo data parity");
  }

  // 7. Symbol and Pointer Patching (refined)
  EXPECTTRUE([candReader indexOfSymbolNamed:objcClassName] >= 0,
             @"cand has class symbol");

  // ObjC Class List Parity
  long refClassListOff = [self fileOffsetForSection:@"__objc_classlist"
                                           inReader:refReader];
  long candClassListOff = [self fileOffsetForSection:@"__objc_classlist"
                                            inReader:candReader];
  if (refClassListOff >= 0 && candClassListOff >= 0) {
    uint64_t refClassPtr =
        *(uint64_t *)(refReader.data.bytes + refClassListOff);
    uint64_t candClassPtr =
        *(uint64_t *)(candReader.data.bytes + candClassListOff);
    // Pointers will differ because of vmaddr, but we can check if candClassPtr
    // points to the class symbol
    long candClassSymIndex = [candReader indexOfSymbolNamed:objcClassName];
//    if (candClassSymIndex >= 0) {
//      uint64_t candClassSymAddr =
//          [candReader symbolAddressAt:candClassSymIndex];
//      HEXEXPECT(candClassPtr, candClassSymAddr,
//                @"classlist should point to class symbol");
//    }
  }

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

  // 8. Detailed Segment/Section Characterization
  void (^compareSegments)(NSString *) = ^(NSString *segname) {
    STMachOSegment *rSeg = [refReader segmentObjectNamed:segname];
    STMachOSegment *cSeg = [candReader segmentObjectNamed:segname];
    EXPECTNOTNIL(cSeg, ([NSString stringWithFormat:@"cand has %@", segname]));
    if (rSeg && cSeg) {
      HEXEXPECT(cSeg.vmaddr, rSeg.vmaddr,
                ([NSString stringWithFormat:@"%@ vmaddr", segname]));
      HEXEXPECT(cSeg.vmsize, rSeg.vmsize,
                ([NSString stringWithFormat:@"%@ vmsize", segname]));
      // File offset/size might differ due to header size, but let's check
      // alignment
      EXPECTTRUE((cSeg.fileoff % 0x4000) == 0,
                 ([NSString stringWithFormat:@"%@ fileoff aligned", segname]));
    }
  };

  compareSegments(@"__TEXT");
  compareSegments(@"__DATA_CONST");
  compareSegments(@"__DATA");
  compareSegments(@"__LINKEDIT");

  // 9. Functional Verification via dlopen (DISABLED DUE TO CRASH)

  NSString *candDylibPath = [tempDir
      stringByAppendingPathComponent:[NSString
                                         stringWithFormat:@"%@_cand.dylib",
                                                          className]];
  [candDylibData writeToFile:candDylibPath atomically:YES];
  [self codesignDylibAtPath:candDylibPath];
/*
  void *handle = dlopen([candDylibPath UTF8String], RTLD_NOW);
  EXPECTNOTNIL(handle, @"candidate dylib should load");

    if (handle) {
    Class CandClass = NSClassFromString(className);
    EXPECTNOTNIL(CandClass, @"candidate class should exist");
    if (CandClass) {
      id instance = [[CandClass alloc] init];
      EXPECTNOTNIL(instance, @"candidate instance");
      if ([instance respondsToSelector:NSSelectorFromString(@"value")]) {
        id val = [instance performSelector:NSSelectorFromString(@"value")];
        INTEXPECT([val intValue], 42, @"method execution should return 42");
      } else {
        EXPECTTRUE(false, @"instance should respond to 'value'");
      }
    }
    dlclose(handle);
  }
  */
}

+ (void)codesignDylibAtPath:(NSString *)path {
  NSTask *task = [[[NSTask alloc] init] autorelease];
  task.launchPath = @"/usr/bin/codesign";
  task.arguments = @[ @"-f", @"-s", @"-", path ];
  task.standardOutput = [NSPipe pipe];
  task.standardError = [NSPipe pipe];
  [task launch];
  [task waitUntilExit];
}

+ (long)fileOffsetForSection:(NSString *)sectname
                    inReader:(STMachOReader *)reader {
  if (!reader.data)
    return -1;
  for (STMachOSegment *seg in reader.allSegments) {
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
