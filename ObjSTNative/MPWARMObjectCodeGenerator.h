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

@property (nonatomic,assign) int defaultFunctionStackSpace;

-(void)generateFunctionNamed:(NSString*)name body:(void(^)(MPWARMObjectCodeGenerator* gen))block;
-(void)generateFunctionNamed:(NSString*)name stackSpace:(int)stackSpace body:(void(^)(MPWARMObjectCodeGenerator* gen))block;
-(void)generateBranchAndLinkWithOffset:(int)offset;
-(void)generateBranchAndLinkWithRegister:(int)theRegister;
-(void)generateCallToExternalFunctionNamed:(NSString*)name;
-(void)generateMessageSendToSelector:(NSString*)selector;
-(void)generateJittedMessageSendToSelector:(NSString*)selector;
-(void)generateAddDest:(int)destReg source1:(int)source1Reg source2:(int)source2Reg;
-(void)generateAddDest:(int)destReg source:(int)sourceReg immediate:(int)immediateValue;
-(void)generateSubDest:(int)destReg source1:(int)source1Reg source2:(int)source2Reg;
-(void)generateMulDest:(int)destReg source1:(int)source1Reg source2:(int)source2Reg;
-(void)clearRegister:(int)regno;
-(void)loadRegister:(int)destReg withConstantAdress:(void*)addressp;
-(void)loadRegister:(int)destReg fromContentsOfAdressInRegister:(int)sourceReg1;
-(void)loadRegister:(int)destReg fromContentsOfConstantAdress:(void*)addressp;
-(void)loadRegister:(int)destReg withPCRelativeConstantAdress:(void*)addressp;
-(void)loadRegister:(int)destReg withEmbeddedPointer:(void*)addressp;
-(void)reserveStackSpace:(int)amount;
-(void)generateMoveRegisterFrom:(int)from to:(int)to;
-(void)generateMoveConstant:(int)constant to:(int)regno;
-(void)generateSaveRegister:(int)reg1 andRegister:(int)reg2 relativeToRegister:(int)storeReg offset:(int)offset rewrite:(BOOL)rewrite pre:(BOOL)isPre;
-(void)generateLoadRegister:(int)reg1 andRegister:(int)reg2 relativeToRegister:(int)storeReg offset:(int)offset rewrite:(BOOL)rewrite pre:(BOOL)isPre;

-(void)generateReturn;
-(unsigned int)adrpToDestReg:(int)destReg withPageOffset:(long)pagediff;
-(void)appendWord32:(unsigned int)word;



-(MPWJittableData*)generatedCode;

@end



NS_ASSUME_NONNULL_END
