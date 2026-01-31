//
//  MPWMachOLinker.h
//  ObjSTNative
//
//  Internal linker: transforms object file data into a loadable dylib
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@class MPWMachOWriter;
@class MPWMachOSectionWriter;
@class MPWMachODylibWriter;

// Represents an internal relocation that needs pointer patching
@interface MPWInternalRelocation : NSObject
@property (nonatomic, strong) NSString *symbolName;        // Target symbol name
@property (nonatomic, weak) MPWMachOSectionWriter *patchSection;   // Section containing the pointer to patch
@property (nonatomic, assign) long offsetInSection;        // Offset of pointer within section
@property (nonatomic, assign) long targetAddress;          // Resolved address (filled in later)
@end

@interface MPWMachOLinker : NSObject

// Link the object file data from an MPWMachOWriter into a dylib
// Returns the dylib data ready to be written to disk and codesigned
-(NSData*)linkToDylibWithInstallName:(NSString*)installName
                          fromWriter:(MPWMachOWriter*)objectWriter;

// Lower-level: link specific section writers
-(NSData*)linkToDylibWithInstallName:(NSString*)installName
                     sectionWriters:(NSArray<MPWMachOSectionWriter*>*)sections
                       symbolWriter:(MPWMachOWriter*)symbolSource;

@end

NS_ASSUME_NONNULL_END
