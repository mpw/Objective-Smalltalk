//
//  MPWARMObjectCodeGenerator.m
//  ObjSTNative
//
//  Created by Marcel Weiher on 04.09.22.
//
//  http://kitoslab-eng.blogspot.com/2012/10/armv8-aarch64-instruction-encoding.html
//  https://weinholt.se/articles/arm-a64-instruction-set/
//  

#import "MPWARMObjectCodeGenerator.h"
#import "MPWJittableData.h"
#import <objc/message.h>
#import "MPWMachOSectionWriter.h"

@implementation MPWARMObjectCodeGenerator

+(id)defaultTarget
{
    return [[[MPWJittableData alloc] initWithCapacity:16384] autorelease];
}

-(MPWJittableData*)generatedCode
{
    MPWJittableData *data=(MPWJittableData*)[self target];
    [data makeExecutable];
    return data;
}

-(void)appendWord32:(unsigned int)word
{
    [self appendBytes:&word length:4];
}

-(void)generateReturn
{
    // x10x 0110 x10x xxxx xxxx xxnn nnnx xxxx  -  ret Rn
    // 1101 0110 0101 1111 0000 0011 1100 0000  -  ret Rn
    [self appendWord32:0xd65f03c0];
}


-(void)generateOp:(int)opcode op2:(int)op2 dest:(int)destReg source1:(int)source1Reg source2:(int)source2Reg
{
    unsigned int instr = opcode << 24;
    instr |= op2 << 8;
    instr |= (destReg & 31);
    instr |= (source1Reg & 31) << 5;
    instr |= (source2Reg & 31) << 16;
    [self appendWord32:instr];
}

-(long)currentOffset
{
    return [self length];
}

-(void)generateOp:(int)opcode dest:(int)destReg source1:(int)source1Reg source2:(int)source2Reg
{
    [self generateOp:opcode op2:0 dest:destReg source1:source1Reg source2:source2Reg];
}

-(void)generateAddDest:(int)destReg source1:(int)source1Reg source2:(int)source2Reg
{
    [self generateOp:0x8b dest:destReg source1:source1Reg source2:source2Reg];
}

-(void)generateAddDest:(int)destReg source:(int)sourceReg immediate:(int)immediateValue
{
    unsigned int base = 0x91000000;
    base |= destReg & 31;
    base |= (sourceReg & 31) << 5;
    base |= (immediateValue & 4095) << 10;
    [self appendWord32:base];
//    [self generateOp:0x8b dest:destReg source1:source1Reg source2:0];
}

-(void)generateSubDest:(int)destReg source1:(int)source1Reg source2:(int)source2Reg
{
    [self generateOp:0xcb dest:destReg source1:source1Reg source2:source2Reg];
}

-(void)generateMulDest:(int)destReg source1:(int)source1Reg source2:(int)source2Reg
{
    [self generateOp:0x9b op2:0x7c dest:destReg source1:source1Reg source2:source2Reg];
}

-(void)loadRegister:(int)destReg fromContentsOfAdressInRegister:(int)sourceReg1
{
    unsigned int baseword=0xf9400000;
    baseword |= destReg & 31;
    baseword |= (sourceReg1 & 31) << 5;
    [self appendWord32:baseword];
}

-(void)loadRegister:(int)destReg withConstantAdress:(void*)addressp
{
    long address = (long)addressp;
    long pc = (long)[(NSData*)[self target] bytes] + [self length];
    long pcpage = pc >> 12;
    long addresspage = address >> 12;
    long pagediff = addresspage - pcpage;
    int page_offset = address & 4095;
    int hibits = (int)(pagediff >> 2);
    int lobits = pagediff & 3;
    unsigned int adrp_base = 0x90000000;
    unsigned int adrp = adrp_base | (destReg & 31) | (hibits << 5 ) | (lobits << 29);
    [self appendWord32:adrp];
    [self generateAddDest:destReg source:destReg immediate:page_offset];
}

-(void)loadRegister:(int)destReg fromContentsOfConstantAdress:(void*)addressp
{
    [self loadRegister:destReg withConstantAdress:addressp];
    [self loadRegister:destReg fromContentsOfAdressInRegister:destReg];
}

-(void)generateBranchAndLinkWithOffset:(int)offset
{
    [self appendWord32:0x94000000 | (offset  >> 2)];
}

-(void)generateBranchAndLinkWithRegister:(int)theRegister
{
    [self appendWord32:0xd63f0000 | ((theRegister & 31) << 5)];
}

-(void)generateBranchWithRegister:(int)theRegister
{
    [self appendWord32:0xd61f0000 | ((theRegister & 31) << 5)];
}

-(void)generateMoveConstant:(int)constant to:(int)regno
{
    unsigned int baseword=0xd2800000;
    baseword |= regno & 31;
    baseword |= (constant & 0xffff) << 5;
    [self appendWord32:baseword];
}

-(void)generateCallToExternalFunctionNamed:(NSString*)name
{
    [self declareExternalFunction:name];
    [self addRelocationEntryForSymbol:name];
    [self generateBranchAndLinkWithOffset:0];
}

-(void)generateMessageSendToSelector:(NSString*)selector
{
    NSString *functionName=[@"_objc_msgSend$" stringByAppendingString:selector];
    [self generateCallToExternalFunctionNamed:functionName];
}


-(void)generateJittedMessageSendToSelector:(NSString*)selector
{
    [self loadRegister:9 withConstantAdress:objc_msgSend];
    [self loadRegister:1 withConstantAdress:NSSelectorFromString(selector)];
    [self generateBranchAndLinkWithRegister:9];
}

-(void)saveRegister:(int)reg1 andRegister:(int)reg2 relativeToRegister:(int)storeReg offset:(int)offset rewrite:(BOOL)rewrite
{
    unsigned int base = 0xa9000000;
    base |= reg1 & 31;
    base |= (reg2 & 31) << 10;
    base |= (storeReg & 31) << 5;
    int offsetdiv8 = offset >> 3;
    base |= (offsetdiv8 & 127) << 15;
    if (offset) {
        base |= 1 << 23;
    }
//    NSAssert1(base == 0xa9bd7bfd, @"doesn't match: 0x%x vs. 0xa9bd7bfd", base);
    [self appendWord32:base];     // stp    x29, x30, [sp, #-0x30]!
}




-(void)generateSaveLinkRegisterAndFramePtr
{
    [self saveRegister:29 andRegister:30 relativeToRegister:31 offset:-0x30 rewrite:YES];
}

-(void)generateRestoreLinkRegisterAndFramePtr
{
    [self appendWord32:0xa8c37bfd];
}

-(void)generateCreateReturnAddressProtectionHash
{
    [self appendWord32:0xd503237f];
}

-(void)generateCheckReturnAddressProtectionHash
{
    [self appendWord32:0xd50323ff];
}

-(void)generateStartOfFunctionNamed:(NSString*)name
{
    [self declareGlobalSymbol:name];
    [self generateSaveLinkRegisterAndFramePtr];
}

-(void)generateEndOfFunction
{
    [self generateRestoreLinkRegisterAndFramePtr];
    [self generateReturn];
}

-(void)generateFunctionNamed:(NSString*)name body:(void(^)(MPWARMObjectCodeGenerator* gen))block
{
    [self generateStartOfFunctionNamed:name];
    block(self);
    [self generateEndOfFunction];
}

-(void)generateMoveRegisterFrom:(int)from to:(int)to
{
    unsigned int base = 0xaa0003e0;
    base |= to & 31;
    base |= (from & 31) << 16;
    [self appendWord32:base];
}

@end



#import <MPWFoundation/DebugMacros.h>
#import "MPWMachOWriter.h"
#import "MPWMachOReader.h"

@implementation MPWARMObjectCodeGenerator(testing) 

typedef long (*IMPINTINT)(long, long);
typedef long (*IMPPTR)(long*);
typedef long (*IMPPTRPTR)(long*,long*);
typedef long (*VOIDPTR)(void);

+(NSData*)codeFor:(void(^)(MPWARMObjectCodeGenerator* gen))block
{
    MPWARMObjectCodeGenerator *g=[self stream];
    block(g);
    [g generateReturn];
    return [g generatedCode];
}

+(IMPINTINT)fnFor:(void(^)(MPWARMObjectCodeGenerator* gen))block
{
    NSData *d=[self codeFor:block];
    return (IMPINTINT)[d bytes];
}

+(void)testGenerateReturn
{
    NSData *code=[self codeFor:^(MPWARMObjectCodeGenerator *gen) {}];
    INTEXPECT(code.length,4,@"length of generated code");
    IMP fn=(IMP)[code bytes];
    EXPECTTRUE(true, @"before call");
    fn();
    EXPECTTRUE(true, @"got here");
}



+(void)testGenerateAdd
{
    NSData *code=[self codeFor:^(MPWARMObjectCodeGenerator *gen) {
        [gen generateAddDest:0 source1:0 source2:1];
    }];
    INTEXPECT(code.length,8,@"length of generated code");
    IMPINTINT addfn=(IMPINTINT)[code bytes];
    long result=addfn(3,4);
    INTEXPECT(result,7,@"3+4");
}

+(void)testGenerateImmediateAdd
{
    NSData *code=[self codeFor:^(MPWARMObjectCodeGenerator *gen) {
        [gen generateAddDest:0 source:0 immediate:4];
    }];
    IMPINTINT addfn=(IMPINTINT)[code bytes];
    long result=addfn(3,0);
    INTEXPECT(result,7,@"3+4");
}

+(void)testGenerateSub
{
    IMPINTINT subfn = [self fnFor:^(MPWARMObjectCodeGenerator *gen) {
        [gen generateSubDest:0 source1:0 source2:1];
    }];
    long result=subfn(40,2);
    INTEXPECT(result,38,@"40-2");
}

+(void)testGenerateMul
{
    IMPINTINT mulfn = [self fnFor:^(MPWARMObjectCodeGenerator *gen) {
        [gen generateMulDest:0 source1:0 source2:1];
    }];
    long result=mulfn(9,5);
    INTEXPECT(result,45,@"9*5");
}

+(void)testGenerateSubReverseOrder
{
    IMPINTINT subfn = [self fnFor:^(MPWARMObjectCodeGenerator *gen) {
        [gen generateSubDest:0 source1:1 source2:0];
    }];
    long result=subfn(3,40);
    INTEXPECT(result,37,@"40-3");
}

+(void)testGenerateDereferencePointerPassedIn
{
    IMPPTR loadfn = (IMPPTR)[self fnFor:^(MPWARMObjectCodeGenerator *gen) {
        [gen loadRegister:0 fromContentsOfAdressInRegister:0];
    }];
    long numberToLoad = 43267;
    long result = loadfn(&numberToLoad);
    INTEXPECT(result,numberToLoad,@"should have loaded the number");
}

+(void)testGenerateSubtractPointedAtLongs
{
    IMPPTRPTR subptrfn = (IMPPTRPTR)[self fnFor:^(MPWARMObjectCodeGenerator *gen) {
        [gen loadRegister:1 fromContentsOfAdressInRegister:1];
        [gen loadRegister:0 fromContentsOfAdressInRegister:0];
        [gen generateSubDest:0 source1:0 source2:1];
    }];
    long firstNumber = 45;
    long secondNumber = 3;
    long result = subptrfn(&firstNumber,&secondNumber);
    INTEXPECT(result,42,@"45-3");
}

+(void)testGenerateCodeWithEmbeddedPointer
{
    long myData[2]={};
    long *dataptr = myData;
    VOIDPTR loadFromPtr = (VOIDPTR)[self fnFor:^(MPWARMObjectCodeGenerator *gen) {
        [gen loadRegister:0 fromContentsOfConstantAdress:dataptr];
        
    }];
    INTEXPECT(loadFromPtr(),0,@"0");
    myData[0]=20;
    INTEXPECT(loadFromPtr(),20,@"20");
    myData[0]=42;
    INTEXPECT(loadFromPtr(),42,@"42");
}

static BOOL iWasCalled=NO;
static void callme() {
    iWasCalled=YES;
}

+(void)testGenerateBranchToPointerPassedAsArg
{
    IMPPTR callPassedFun = (IMPPTR)[self fnFor:^(MPWARMObjectCodeGenerator *gen) {
        [gen generateBranchWithRegister:0];
        
    }];
    iWasCalled=NO;
    EXPECTFALSE(iWasCalled, @"not called");
    callPassedFun( (long*)callme  );
    EXPECTTRUE(iWasCalled, @"called");
}

+(void)testGenerateCallToPointerPassedAsArg
{
    IMPPTR callPassedFun = (IMPPTR)[self fnFor:^(MPWARMObjectCodeGenerator *gen) {
        [gen generateSaveLinkRegisterAndFramePtr];
        [gen generateBranchAndLinkWithRegister:0];
        [gen generateRestoreLinkRegisterAndFramePtr];
        
    }];
    iWasCalled=NO;
    EXPECTFALSE(iWasCalled, @"not called");
    callPassedFun( (long*)callme  );
    EXPECTTRUE(iWasCalled, @"called");
}


 
+(void)testCanGenerateReturnAddressProtection
{
    IMPPTR callPassedFun = (IMPPTR)[self fnFor:^(MPWARMObjectCodeGenerator *gen) {
        [gen generateCreateReturnAddressProtectionHash];
        [gen generateSaveLinkRegisterAndFramePtr];
        [gen generateBranchAndLinkWithRegister:0];
        [gen generateRestoreLinkRegisterAndFramePtr];
        [gen generateCheckReturnAddressProtectionHash];
    }];
    iWasCalled=NO;
    EXPECTFALSE(iWasCalled, @"not called");
    callPassedFun( (long*)callme  );
    EXPECTTRUE(iWasCalled, @"called");
}

+(void)testGenerateMachOWithCallToExternalFunction
{
    MPWMachOWriter *writer = [MPWMachOWriter stream];
    MPWARMObjectCodeGenerator *g=[self stream];
    g.symbolWriter = writer;
    g.relocationWriter = writer.textSectionWriter;
    [g generateFunctionNamed:@"_theFunction" body:^(MPWARMObjectCodeGenerator *gen) {
        [g generateCallToExternalFunctionNamed:@"_other"];
    }];
    [writer addTextSectionData:(NSData*)[g target]];
//    NSLog(@"before write file");
    [writer writeFile];
//    NSLog(@"after write file");
    NSData *macho=[writer data];
    [macho writeToFile:@"/tmp/theFunction-calls-other.o" atomically:YES];
    MPWMachOReader *reader=[[[MPWMachOReader alloc] initWithData:macho] autorelease];
    INTEXPECT( [[reader textSection] offsetOfRelocEntryAt:0], 4,@"location of call to _other");
    IDEXPECT( [[reader textSection] nameOfRelocEntryAt:0], @"_other",@"name of call to _other");
}

+(void)testGenerateMachOWithMessageSend
{
    MPWMachOWriter *writer = [MPWMachOWriter stream];
    MPWARMObjectCodeGenerator *g=[self stream];
    g.symbolWriter = writer;
    g.relocationWriter = writer.textSectionWriter;
    [g generateFunctionNamed:@"_lengthOfString" body:^(MPWARMObjectCodeGenerator *gen) {
        [g generateMessageSendToSelector:@"length"];
    }];
    [writer addTextSectionData:(NSData*)[g target]];
    [writer writeFile];
    NSData *macho=[writer data];
//    [macho writeToFile:@"/tmp/theFunction-sends-length.o" atomically:YES];
    MPWMachOReader *reader=[[[MPWMachOReader alloc] initWithData:macho] autorelease];
    INTEXPECT( [[reader textSection] offsetOfRelocEntryAt:0], 4,@"location of call to _other");
    IDEXPECT( [[reader textSection] nameOfRelocEntryAt:0], @"_objc_msgSend$length",@"name of msg send");
}

+(void)testGenerateMessageSendAndComputation
{
    MPWARMObjectCodeGenerator *g=[self stream];
    [g generateFunctionNamed:@"_lengthOfString" body:^(MPWARMObjectCodeGenerator *gen) {
        [g generateMessageSendToSelector:@"hash"];
        [gen generateAddDest:0 source:0 immediate:200];
    }];
    MPWJittableData *d=[g generatedCode];
    NSData *code=[NSData dataWithBytes:d.bytes length:d.length];
    [code writeToFile:@"/tmp/hashPlus200.code" atomically:YES];
}

typedef long (*IDPTR)(id,SEL);


+(void)testJITMessageSendAndComputation
{
    MPWARMObjectCodeGenerator *g=[self stream];
    [g generateFunctionNamed:@"-[TestClass method]" body:^(MPWARMObjectCodeGenerator *gen) {
        [g generateJittedMessageSendToSelector:@"hash"];
        [gen generateAddDest:0 source:0 immediate:200];
    }];
    MPWJittableData *d=[g generatedCode];
    IDPTR fn = (IDPTR)[d bytes];
    long myHash = [self hash];
    long hashPlus200 = fn( self, @selector(hash));
    INTEXPECT( hashPlus200- myHash, 200, @"the hash");
}

typedef long (*IDIDPTR)(id,SEL,id);


+(void)testJITLengthOfPassedStringPlus3
{
    MPWARMObjectCodeGenerator *g=[self stream];
    [g generateFunctionNamed:@"-[TestClass lengthOfStringPlus3]" body:^(MPWARMObjectCodeGenerator *gen) {
        [g generateMoveRegisterFrom:2 to:0];
        [g generateJittedMessageSendToSelector:@"length"];
        [gen generateAddDest:0 source:0 immediate:3];
    }];
    MPWJittableData *d=[g generatedCode];
    IDIDPTR fn = (IDIDPTR)[d bytes];
    long lengthPlush3 = fn( self , @selector(length), @"Test String");
    INTEXPECT( lengthPlush3, 14, @"length of string plus 3");
}

+(NSArray*)testSelectors
{
   return @[
       @"testGenerateReturn",
       @"testGenerateAdd",
       @"testGenerateImmediateAdd",
       @"testGenerateSub",
       @"testGenerateMul",
       @"testGenerateSubReverseOrder",
       @"testGenerateDereferencePointerPassedIn",
       @"testGenerateSubtractPointedAtLongs",
       @"testGenerateCodeWithEmbeddedPointer",
       @"testGenerateBranchToPointerPassedAsArg",
       @"testGenerateCallToPointerPassedAsArg",
       @"testCanGenerateReturnAddressProtection",
       @"testGenerateMachOWithCallToExternalFunction",
       @"testGenerateMachOWithMessageSend",
       @"testGenerateMessageSendAndComputation",
       @"testJITMessageSendAndComputation",
       @"testJITLengthOfPassedStringPlus3",
			];
}

@end
