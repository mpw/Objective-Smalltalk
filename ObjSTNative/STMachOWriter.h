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

@interface STMachOWriter : STObjectFileWriter <SymbolWriter>

@property (nonatomic, readonly) STMachOSectionWriter *textSectionWriter;

-(void)generateMachO;
-(NSData*)data;
-(int)declareExternalSymbol:(NSString*)symbol;
-(STMachOSectionWriter*)addSectionWriterWithSegName:(NSString*)segname sectName:(NSString*)sectname flags:(int)flags;
-(void)writeNSStringLiteral:(NSString*)theString label:(NSString*)label;
-(NSString*)writeBlockDescritorWithCodeAtSymbol:(NSString*)codeSymbol blockSymbol:(NSString*)blockSymbol signature:(NSString*)signature;
-(void)writeBlockLiteralWithCodeAtSymbol:(NSString*)codeSymbol blockSymbol:(NSString*)blockSymbol signature:(NSString*)signature global:(BOOL)global;
-(void)addTextSectionData:(NSData*)data;
-(NSString*)addClassReferenceForClass:(NSString*)className;
-(NSString*)addClassReferenceForClass:(NSString*)className prefix:(NSString*)prefix;




@end

NS_ASSUME_NONNULL_END
