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
-(void)generateBranchAndLinkWithOffset:(int)offset;
-(void)generateBranchAndLinkWithRegister:(int)theRegister;
-(void)generateCallToExternalFunctionNamed:(NSString*)name;
-(void)generateMessageSendToSelector:(NSString*)selector;
-(void)generateJittedMessageSendToSelector:(NSString*)selector;
-(void)generateAddDest:(int)destReg source1:(int)source1Reg source2:(int)source2Reg;
-(void)generateAddDest:(int)destReg source:(int)sourceReg immediate:(int)immediateValue;
-(void)generateSubDest:(int)destReg source1:(int)source1Reg source2:(int)source2Reg;
-(void)generateMulDest:(int)destReg source1:(int)source1Reg source2:(int)source2Reg;
-(void)loadRegister:(int)destReg withConstantAdress:(void*)addressp;
-(void)loadRegister:(int)destReg fromContentsOfAdressInRegister:(int)sourceReg1;
-(void)loadRegister:(int)destReg fromContentsOfConstantAdress:(void*)addressp;
-(void)generateMoveRegisterFrom:(int)from to:(int)to;
-(void)generateMoveConstant:(int)constant to:(int)regno;
-(void)generateSaveRegister:(int)reg1 andRegister:(int)reg2 relativeToRegister:(int)storeReg offset:(int)offset rewrite:(BOOL)rewrite pre:(BOOL)isPre;
-(void)generateLoadRegister:(int)reg1 andRegister:(int)reg2 relativeToRegister:(int)storeReg offset:(int)offset rewrite:(BOOL)rewrite pre:(BOOL)isPre;


-(MPWJittableData*)generatedCode;

@end



NS_ASSUME_NONNULL_END
