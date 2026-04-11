//
//  MPWMachOWriter.h
//  ObjSTNative
//
//  Created by Marcel Weiher on 14.09.22.
//

#import <MPWFoundation/MPWFoundation.h>
#import "STObjectCodeGeneratorARM.h"
#import "STObjectFileWriter.h"

NS_ASSUME_NONNULL_BEGIN

@class STMachOSectionWriter;
@class STNativeCompiler;

@interface STMachOWriter : STObjectFileWriter <SymbolWriter>

@property (nonatomic, readonly) STMachOSectionWriter *textSectionWriter;
@property (nonatomic, copy) NSString *outputDirectory;
@property (nonatomic, copy) NSString *artifactBaseName;
@property (nonatomic, copy, nullable) NSString *objectFileName;
@property (nonatomic, copy, nullable) NSString *dylibFileName;
@property (nonatomic, copy, nullable) NSString *dylibInstallNameOverride;

-(void)generateMachO;
-(NSData*)data;
-(STMachOSectionWriter*)addSectionWriterWithSegName:(NSString*)segname sectName:(NSString*)sectname flags:(int)flags;
-(void)writeNSStringLiteral:(NSString*)theString label:(NSString*)label;
-(NSString*)writeBlockDescritorWithCodeAtSymbol:(NSString*)codeSymbol blockSymbol:(NSString*)blockSymbol signature:(NSString*)signature;
-(void)writeBlockLiteralWithCodeAtSymbol:(NSString*)codeSymbol blockSymbol:(NSString*)blockSymbol signature:(NSString*)signature global:(BOOL)global;
-(void)addTextSectionData:(NSData*)data;
-(NSString*)addClassReferenceForClass:(NSString*)className;
-(NSString*)addClassReferenceForClass:(NSString*)className prefix:(NSString*)prefix;
-(STNativeCompiler*)compiler;
-(NSString*)objectPath;
-(NSString*)dylibPath;
-(NSString*)dylibInstallName;
-(BOOL)writeSignedDylibToPath:(NSString *)path error:(NSError * _Nullable __autoreleasing *)error;
-(BOOL)writeSignedDylibWithDefaults:(NSError * _Nullable __autoreleasing *)error;

@end

NS_ASSUME_NONNULL_END
