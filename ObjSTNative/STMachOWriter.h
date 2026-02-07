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

@class MPWMachOSectionWriter;

@interface STMachOWriter : STObjectFileWriter <SymbolWriter>

@property (nonatomic, readonly) MPWMachOSectionWriter *textSectionWriter;

-(void)generateMachO;
-(NSData*)data;
-(int)declareExternalSymbol:(NSString*)symbol;
-(MPWMachOSectionWriter*)addSectionWriterWithSegName:(NSString*)segname sectName:(NSString*)sectname flags:(int)flags;
-(void)writeNSStringLiteral:(NSString*)theString label:(NSString*)label;
-(NSString*)writeBlockDescritorWithCodeAtSymbol:(NSString*)codeSymbol blockSymbol:(NSString*)blockSymbol signature:(NSString*)signature;
-(void)writeBlockLiteralWithCodeAtSymbol:(NSString*)codeSymbol blockSymbol:(NSString*)blockSymbol signature:(NSString*)signature global:(BOOL)global;
-(void)addTextSectionData:(NSData*)data;
-(NSString*)addClassReferenceForClass:(NSString*)className;
-(NSString*)addClassReferenceForClass:(NSString*)className prefix:(NSString*)prefix;




@end

NS_ASSUME_NONNULL_END
