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

@implementation MPWARMObjectCodeGenerator

+(id)defaultTarget
{
    return [[[MPWJittableData alloc] initWithCapacity:16384] autorelease];
}

-(NSData*)generatedCode
{
    [(MPWJittableData*)[self target] makeExecutable];
    return (NSData*)[self target];
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

-(void)loadRegister:(int)destReg fromAdressInRegister:(int)sourceReg1
{
    unsigned int baseword=0xf9400000;
    baseword |= destReg & 31;
    baseword |= (sourceReg1 & 31) << 5;
    [self appendWord32:baseword];
}

-(void)loadRegister:(int)destReg fromAddress:(void*)addressp
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
    [self loadRegister:destReg fromAdressInRegister:destReg];
}


@end



#import <MPWFoundation/DebugMacros.h>

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
        [gen loadRegister:0 fromAdressInRegister:0];
    }];
    long numberToLoad = 43267;
    long result = loadfn(&numberToLoad);
    INTEXPECT(result,numberToLoad,@"should have loaded the number");
}

+(void)testGenerateSubtractPointedAtLongs
{
    IMPPTRPTR subptrfn = (IMPPTRPTR)[self fnFor:^(MPWARMObjectCodeGenerator *gen) {
        [gen loadRegister:1 fromAdressInRegister:1];
        [gen loadRegister:0 fromAdressInRegister:0];
        [gen generateSubDest:0 source1:0 source2:1];
    }];
    long firstNumber = 45;
    long secondNumber = 3;
    long result = subptrfn(&firstNumber,&secondNumber);
    INTEXPECT(result,42,@"45-3");
}

+(void)testAddImmediate
{
    
}

+(void)testGenerateCodeWithEmbeddedPointer
{
    long myData[2]={};
    long *dataptr = myData;
    VOIDPTR loadFromPtr = (VOIDPTR)[self fnFor:^(MPWARMObjectCodeGenerator *gen) {
        [gen loadRegister:0 fromAddress:dataptr];
        
    }];
    INTEXPECT(loadFromPtr(),0,@"0");
    myData[0]=20;
    INTEXPECT(loadFromPtr(),20,@"20");
    myData[0]=42;
    INTEXPECT(loadFromPtr(),42,@"42");
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
			];
}

@end
