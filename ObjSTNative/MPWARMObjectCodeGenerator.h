//
//  MPWARMObjectCodeGenerator.h
//  ObjSTNative
//
//  Created by Marcel Weiher on 04.09.22.
//

#import <ObjSTNative/MPWByteStreamWithSymbols.h>

NS_ASSUME_NONNULL_BEGIN

@class MPWJittableData;

@interface MPWARMObjectCodeGenerator : MPWByteStreamWithSymbols

-(void)generateFunctionNamed:(NSString*)name body:(void(^)(MPWARMObjectCodeGenerator* gen))block;
-(void)generateCallToExternalFunctionNamed:(NSString*)name;
-(void)generateMessageSendToSelector:(NSString*)selector;
-(void)generateAddDest:(int)destReg source1:(int)source1Reg source2:(int)source2Reg;
-(void)generateAddDest:(int)destReg source:(int)sourceReg immediate:(int)immediateValue;
-(void)generateSubDest:(int)destReg source1:(int)source1Reg source2:(int)source2Reg;
-(void)generateMulDest:(int)destReg source1:(int)source1Reg source2:(int)source2Reg;
-(void)loadRegister:(int)destReg fromContentsOfAdressInRegister:(int)sourceReg1;
-(void)loadRegister:(int)destReg fromContentsOfConstantAdress:(void*)addressp;
-(void)generateMoveRegisterFrom:(int)from to:(int)to;

-(MPWJittableData*)generatedCode;

@end



NS_ASSUME_NONNULL_END
