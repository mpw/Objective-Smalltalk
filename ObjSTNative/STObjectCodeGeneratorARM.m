//
//  MPWARMObjectCodeGenerator.m
//  ObjSTNative
//
//  Created by Marcel Weiher on 04.09.22.
//
//  http://kitoslab-eng.blogspot.com/2012/10/armv8-aarch64-instruction-encoding.html
//  https://weinholt.se/articles/arm-a64-instruction-set/
//  

#import "STObjectCodeGeneratorARM.h"
#import "STJittableData.h"
#import <objc/message.h>


//   ARM64 register conventions: https://developer.apple.com/documentation/xcode/writing-arm64-code-for-apple-platforms
//   x0-x8   arguments + return value
//   x9-x17  temporary (not saved)
//   x18     platform register, Apple says do not use
//   x19-x28 saved local registers
//   x29     FP frame pointer
//   x30     link register
//   x31     SP / zero register dependingon instruction

@implementation STObjectCodeGeneratorARM

-(instancetype)initWithTarget:(id)aTarget
{
    self=[super initWithTarget:aTarget];
    self.defaultFunctionStackSpace=0x120;
    return self;
}

+(id)defaultTarget
{
    return [[[STJittableData alloc] initWithCapacity:16384] autorelease];
}

-(STJittableData*)generatedCode
{
    STJittableData *data=(STJittableData*)[self target];
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

-(void)clearRegister:(int)regno
{
    unsigned int base=0xd2800000;
    base |= regno & 31;
    [self appendWord32:base];
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

-(void)generateMo:(int)destReg source:(int)sourceReg immediate:(int)immediateValue
{
    unsigned int base = 0x91000000;
    base |= destReg & 31;
    base |= (sourceReg & 31) << 5;
    base |= (immediateValue & 4095) << 10;
    [self appendWord32:base];
    //    [self generateOp:0x8b dest:destReg source1:source1Reg source2:0];
}

-(void)generateSubDest:(int)destReg source:(int)sourceReg immediate:(int)immediateValue
{
    unsigned int base = 0xd1000000;
    base |= destReg & 31;
    base |= (sourceReg & 31) << 5;
    base |= (immediateValue & 4095) << 10;
    [self appendWord32:base];
    //    [self generateOp:0x8b dest:destReg source1:source1Reg source2:0];
}

-(void)generateNOP
{
    [self appendWord32:0xd503201f];
}

-(void)generateSubDest:(int)destReg source1:(int)source1Reg source2:(int)source2Reg
{
    [self generateOp:0xcb dest:destReg source1:source1Reg source2:source2Reg];
}

-(void)generateMulDest:(int)destReg source1:(int)source1Reg source2:(int)source2Reg
{
    [self generateOp:0x9b op2:0x7c dest:destReg source1:source1Reg source2:source2Reg];
}

-(void)loadRegister:(int)destReg fromContentsOfAdressInRegister:(int)sourceReg1 offset:(int)offset
{
    unsigned int baseword=0xf8400000;
    baseword |= destReg & 31;
    baseword |= (sourceReg1 & 31) << 5;
    baseword |= offset << 12;
    [self appendWord32:baseword];
}

-(void)loadRegister:(int)destReg fromContentsOfAdressInRegister:(int)sourceReg1
{
    unsigned int baseword=0xf9400000;
    baseword |= destReg & 31;
    baseword |= (sourceReg1 & 31) << 5;
    [self appendWord32:baseword];
}



-(unsigned int)adrpToDestReg:(int)destReg withPageOffset:(long)pagediff
{
    NSAssert2(labs(pagediff) < (1L<<20), @"pagediff %ld/%lx out of range for adrp", pagediff,pagediff);

    int hibits = (int)(pagediff << 3) & (0x7ffff << 5);
    int lobits = pagediff & 3;
    unsigned int adrp_base = 0x90000000;
    unsigned int adrp = adrp_base | (destReg & 31) | (hibits ) | (lobits << 29);
    return adrp;
}

-(long)pageDiffForPC:(long)pc address:(long)address
{
    long pcpage = pc >> 12;
    long addresspage = address >> 12;
    long pagediff = (addresspage - pcpage);
    return pagediff;
}

-(unsigned int)adrpForRegister:(int)destReg address:(long)address pc:(long)pc
{
    long pagediff=[self pageDiffForPC:pc address:address];
    unsigned int adrp=[self adrpToDestReg:destReg withPageOffset:pagediff];
   return adrp;
}


-(void)loadRegister:(int)destReg withPCRelativeConstantAdress:(void*)addressp
{
    long address = (long)addressp;
    int page_offset = address & 0xfff;
    long pc = (long)[(NSData*)[self target] bytes] + [self length];
    unsigned int adrp=[self adrpForRegister:destReg address:address pc:pc];
    [self appendWord32:adrp];
    [self generateAddDest:destReg source:destReg immediate:page_offset];
}

-(long)pc
{
    return (long)[(NSData*)[self target] bytes] + [self length];

}

-(void)loadRegister:(int)destReg withEmbeddedPointer:(void*)addressp
{
    unsigned int base = 0x58000040;
    base |= destReg & 31;
    [self appendWord32:base];     // ldr x0,[pc+4]
    [self appendWord32:0x14000003];     // branch around
    [self appendBytes:&addressp length:8];  // the pointer;    
}

-(void)loadRegister:(int)destReg withConstantAdress:(void*)addressp
{
    long pc = [self pc];
    long address = (long)addressp;
    long pagediff=[self pageDiffForPC:pc address:address];
    if ( (labs(pagediff) >= (1L<<20)) ) {
        [self loadRegister:destReg withEmbeddedPointer:addressp];
    } else {
        [self loadRegister:destReg withPCRelativeConstantAdress:addressp];
    }

}

-(void)loadRegister:(int)destReg pcRelative:(int)pcOffset
{
    unsigned int ldrpc = 0x58000000;
    [self appendWord32:ldrpc];
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


-(void)generateLoadOrStore:(BOOL)isLoad forRegister:(int)reg1 andRegister:(int)reg2 relativeToRegister:(int)storeReg offset:(int)offset rewrite:(BOOL)rewrite pre:(BOOL)isPre
{
    unsigned int base = isLoad ? 0xa8400000: 0xa8000000;
    base |= reg1 & 31;
    base |= (reg2 & 31) << 10;
    base |= (storeReg & 31) << 5;
    int offsetdiv8 = offset >> 3;
    base |= (offsetdiv8 & 127) << 15;
    if (rewrite) {
        base |= 1 << 23;
    }
    if (isPre) {
        base |= 1 << 24;
    }
    [self appendWord32:base];
}

-(void)generateSaveRegister:(int)reg1 andRegister:(int)reg2 relativeToRegister:(int)storeReg offset:(int)offset rewrite:(BOOL)rewrite pre:(BOOL)isPre
{
    [self generateLoadOrStore:NO forRegister:reg1 andRegister:reg2 relativeToRegister:storeReg offset:offset rewrite:rewrite pre:isPre];
}



-(void)generateSaveLinkRegisterAndFramePtr:(int)offset
{
    [self generateSaveRegister:29 andRegister:30 relativeToRegister:31 offset:offset rewrite:NO pre:NO];
}


-(void)generateLoadRegister:(int)reg1 andRegister:(int)reg2 relativeToRegister:(int)storeReg offset:(int)offset rewrite:(BOOL)rewrite pre:(BOOL)isPre
{
    [self generateLoadOrStore:YES forRegister:reg1 andRegister:reg2 relativeToRegister:storeReg offset:offset rewrite:rewrite pre:isPre];
}



-(void)generateRestoreLinkRegisterAndFramePtr:(int)offset
{
    [self generateLoadRegister:29 andRegister:30 relativeToRegister:31 offset:offset rewrite:NO pre:NO];
}

-(void)generateCreateReturnAddressProtectionHash
{
    [self appendWord32:0xd503237f];
}

-(void)generateCheckReturnAddressProtectionHash
{
    [self appendWord32:0xd50323ff];
}

-(void)reserveStackSpace:(int)amount
{
    [self generateSubDest:31 source:31 immediate:amount];
}

-(void)popStackSpace:(int)amount
{
    [self generateAddDest:31 source:31 immediate:amount];
}

-(void)generateStartOfFunctionNamed:(NSString*)name stackSpace:(int)stackSpace
{
    [self declareGlobalSymbol:name];
    [self reserveStackSpace:stackSpace];
    [self generateSaveLinkRegisterAndFramePtr:stackSpace-0x10];
    [self generateAddDest:30 source:31 immediate:stackSpace-0x20];     // set FP
}

-(void)generateEndOfFunctionStackSpace:(int)stackSpace
{
    [self generateRestoreLinkRegisterAndFramePtr:stackSpace-0x10];
    [self popStackSpace:stackSpace];
    [self generateReturn];
}

-(void)generateFunctionNamed:(NSString*)name stackSpace:(int)stackSpace body:(void(^)(STObjectCodeGeneratorARM* gen))block
{
    [self generateStartOfFunctionNamed:name stackSpace:stackSpace];
    block(self);
    [self generateEndOfFunctionStackSpace:stackSpace];
}

-(void)generateFunctionNamed:(NSString*)name body:(void(^)(STObjectCodeGeneratorARM* gen))block
{
    [self generateFunctionNamed:name stackSpace:self.defaultFunctionStackSpace body:block ];
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

@implementation STObjectCodeGeneratorARM(testing) 

typedef long (*IMPINTINT)(long, long);
typedef long (*IMPPTR)(long*);
typedef long (*IMPPTRPTR)(long*,long*);
typedef long (*VOIDPTR)(void);

+(NSData*)codeFor:(void(^)(STObjectCodeGeneratorARM* gen))block
{
    STObjectCodeGeneratorARM *g=[self stream];
    block(g);
    [g generateReturn];
    return (NSData*)[g generatedCode];
}

+(IMPINTINT)fnFor:(void(^)(STObjectCodeGeneratorARM* gen))block
{
    NSData *d=[self codeFor:block];
    return (IMPINTINT)[d bytes];
}

typedef void (*voidvoidfun)(void);

+(void)testGenerateReturn
{
    NSData *code=[self codeFor:^(STObjectCodeGeneratorARM *gen) {}];
    INTEXPECT(code.length,4,@"length of generated code");
    voidvoidfun fn=(voidvoidfun)[code bytes];
    EXPECTTRUE(true, @"before call");
    fn();
    EXPECTTRUE(true, @"got here");
}

+(unsigned int)instructionFor:(void(^)(STObjectCodeGeneratorARM* gen))block
{
    NSData *code=[self codeFor:block];
    NSAssert1(code.length >= 4, @"Had only %ld bytes, need at least 4",code.length);
    return *(unsigned int*)[code bytes];
}


+(void)testGenerateAdd
{
    NSData *code=[self codeFor:^(STObjectCodeGeneratorARM *gen) {
        [gen generateAddDest:0 source1:0 source2:1];
    }];
    INTEXPECT(code.length,8,@"length of generated code");
    IMPINTINT addfn=(IMPINTINT)[code bytes];
    long result=addfn(3,4);
    INTEXPECT(result,7,@"3+4");
}

+(void)testGenerateImmediateAdd
{
    NSData *code=[self codeFor:^(STObjectCodeGeneratorARM *gen) {
        [gen generateAddDest:0 source:0 immediate:4];
    }];
    IMPINTINT addfn=(IMPINTINT)[code bytes];
    long result=addfn(3,0);
    INTEXPECT(result,7,@"3+4");
}

+(void)testGenerateImmediateSub
{
    NSData *code=[self codeFor:^(STObjectCodeGeneratorARM *gen) {
        [gen generateSubDest:0 source:0 immediate:7];
    }];
    IMPINTINT addfn=(IMPINTINT)[code bytes];
    long result=addfn(23,0);
    INTEXPECT(result,16,@"23-7");
}


+(void)testGenerateSub
{
    IMPINTINT subfn = [self fnFor:^(STObjectCodeGeneratorARM *gen) {
        [gen generateSubDest:0 source1:0 source2:1];
    }];
    long result=subfn(40,2);
    INTEXPECT(result,38,@"40-2");
}

+(void)testGenerateMul
{
    IMPINTINT mulfn = [self fnFor:^(STObjectCodeGeneratorARM *gen) {
        [gen generateMulDest:0 source1:0 source2:1];
    }];
    long result=mulfn(9,5);
    INTEXPECT(result,45,@"9*5");
}

+(void)testGenerateSubReverseOrder
{
    IMPINTINT subfn = [self fnFor:^(STObjectCodeGeneratorARM *gen) {
        [gen generateSubDest:0 source1:1 source2:0];
    }];
    long result=subfn(3,40);
    INTEXPECT(result,37,@"40-3");
}

+(void)testGenerateStoreMultiple
{
    unsigned int storeMultipleInstructionPre = [self instructionFor:^(STObjectCodeGeneratorARM *gen) {
        [gen generateSaveRegister:29 andRegister:30 relativeToRegister:31 offset:-0x30 rewrite:YES pre:YES];
    }];
    INTEXPECT(storeMultipleInstructionPre, 0xa9bd7bfd, @"stp    x29, x30, [sp, #-0x30]!" );
    unsigned int storeMultipleInstructionPost = [self instructionFor:^(STObjectCodeGeneratorARM *gen) {
        [gen generateSaveRegister:29 andRegister:30 relativeToRegister:31 offset:-0x30 rewrite:YES pre:NO];
    }];
    INTEXPECT(storeMultipleInstructionPost, 0xa8bd7bfd, @"stp    x29, x30, [sp #-0x30]!" );
}

+(void)testGenerateAddImmediate
{
    unsigned int addImmediate = [self instructionFor:^(STObjectCodeGeneratorARM *gen) {
        [gen generateAddDest:31 source:31 immediate:0x08];
    }];
    HEXEXPECT(addImmediate, 0x910023ff, @"add    sp, sp, #0x8" );
}

+(void)testReserveStackSpace
{
    unsigned int reserveStackx8 = [self instructionFor:^(STObjectCodeGeneratorARM *gen) {
        [gen reserveStackSpace:0x08];
    }];
    HEXEXPECT(reserveStackx8, 0xd10023ff, @"sub    sp, sp, #0x8" );
    unsigned int reserveStackx22 = [self instructionFor:^(STObjectCodeGeneratorARM *gen) {
        [gen reserveStackSpace:0x22];
    }];
    HEXEXPECT(reserveStackx22, 0xd1008bff, @"sub    sp, sp, #0x22" );

}


+(void)testGenerateSubImmediate
{
    unsigned int addImmediate = [self instructionFor:^(STObjectCodeGeneratorARM *gen) {
        [gen generateSubDest:31 source:31 immediate:0x08];
    }];
    HEXEXPECT(addImmediate, 0xd10023ff, @"sub    sp, sp, #0x8" );
}

+(void)testGenerateLoadPCRelative
{
    unsigned int loadPCRelative = [self instructionFor:^(STObjectCodeGeneratorARM *gen) {
        [gen loadRegister:0 pcRelative:0];
    }];
    HEXEXPECT(loadPCRelative, 0x58000000, @"l1: ldr    x0, l1" );
}

+(void)testGenerateLoadMultiple
{
    unsigned int loadMultipleInstruction = [self instructionFor:^(STObjectCodeGeneratorARM *gen) {
        [gen generateLoadRegister:29 andRegister:30 relativeToRegister:31 offset:0x30 rewrite:YES pre:NO];
    }];
    NSAssert2(loadMultipleInstruction== 0xa8c37bfd,@"load multiple: got %x expected %x",loadMultipleInstruction,0xa8c37bfd );
    INTEXPECT(loadMultipleInstruction, 0xa8c37bfd, @"ldp    x29, x30, [sp], 0x030" );
}

+(void)testGenerateDereferencePointerPassedIn
{
    IMPPTR loadfn = (IMPPTR)[self fnFor:^(STObjectCodeGeneratorARM *gen) {
        [gen loadRegister:0 fromContentsOfAdressInRegister:0];
    }];
    long numberToLoad = 43267;
    long result = loadfn(&numberToLoad);
    INTEXPECT(result,numberToLoad,@"should have loaded the number");
}

+(void)testGenerateSubtractPointedAtLongs
{
    IMPPTRPTR subptrfn = (IMPPTRPTR)[self fnFor:^(STObjectCodeGeneratorARM *gen) {
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
    VOIDPTR loadFromPtr = (VOIDPTR)[self fnFor:^(STObjectCodeGeneratorARM *gen) {
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
    IMPPTR callPassedFun = (IMPPTR)[self fnFor:^(STObjectCodeGeneratorARM *gen) {
        [gen generateBranchWithRegister:0];
        
    }];
    iWasCalled=NO;
    EXPECTFALSE(iWasCalled, @"not called");
    callPassedFun( (long*)callme  );
    EXPECTTRUE(iWasCalled, @"called");
}

+(void)testGenerateCallToPointerPassedAsArg
{
    IMPPTR callPassedFun = (IMPPTR)[self fnFor:^(STObjectCodeGeneratorARM *gen) {
        [gen generateSaveLinkRegisterAndFramePtr:0x0];
        [gen generateBranchAndLinkWithRegister:0];
        [gen generateRestoreLinkRegisterAndFramePtr:0x0];
        
    }];
    iWasCalled=NO;
    EXPECTFALSE(iWasCalled, @"not called");
    callPassedFun( (long*)callme  );
    EXPECTTRUE(iWasCalled, @"called");
}


 
+(void)testCanGenerateReturnAddressProtection
{
    IMPPTR callPassedFun = (IMPPTR)[self fnFor:^(STObjectCodeGeneratorARM *gen) {
        [gen generateCreateReturnAddressProtectionHash];
        [gen generateSaveLinkRegisterAndFramePtr:0x0];
        [gen generateBranchAndLinkWithRegister:0];
        [gen generateRestoreLinkRegisterAndFramePtr:0x0];
        [gen generateCheckReturnAddressProtectionHash];
    }];
    iWasCalled=NO;
    EXPECTFALSE(iWasCalled, @"not called");
    callPassedFun( (long*)callme  );
    EXPECTTRUE(iWasCalled, @"called");
}


typedef long (*IDPTR)(id,SEL);


+(void)testJITMessageSendAndComputation
{
    STObjectCodeGeneratorARM *g=[self stream];
    [g generateFunctionNamed:@"-[TestClass method]" body:^(STObjectCodeGeneratorARM *gen) {
        [g generateJittedMessageSendToSelector:@"hash"];
        [gen generateAddDest:0 source:0 immediate:200];
    }];
    STJittableData *d=[g generatedCode];
    IDPTR fn = (IDPTR)[d bytes];
    long myHash = [self hash];
    long hashPlus200 = fn( self, @selector(hash));
    INTEXPECT( hashPlus200- myHash, 200, @"the hash");
}

typedef long (*IDIDPTR)(id,SEL,id);


+(void)testJITLengthOfPassedStringPlus3
{
    STObjectCodeGeneratorARM *g=[self stream];
    [g generateFunctionNamed:@"-[TestClass lengthOfStringPlus3]" body:^(STObjectCodeGeneratorARM *gen) {
        [g generateMoveRegisterFrom:2 to:0];
        [g generateJittedMessageSendToSelector:@"length"];
        [gen generateAddDest:0 source:0 immediate:3];
    }];
    STJittableData *d=[g generatedCode];
    IDIDPTR fn = (IDIDPTR)[d bytes];
    long lengthPlush3 = fn( self , @selector(length), @"Test String");
    INTEXPECT( lengthPlush3, 14, @"length of string plus 3");
}

+(void)testEmbeddedPointerGenerationOverRange
{
    
    const int datalen = 2000000;
    void *dataptr = calloc( datalen+2, sizeof(long) );
    long *longptr = (long*)dataptr;
    for (int i=0;i<datalen;i++) {
        longptr[i]=i;
    }
    for (int i=0;i<datalen;i++) {
        VOIDPTR loadPtr = (VOIDPTR)[self fnFor:^(STObjectCodeGeneratorARM *gen) {
            [gen loadRegister:0 withConstantAdress:dataptr+(i*sizeof(long))];
        }];
        NSString *msg = [NSString stringWithFormat:@"address generated by adrp+add at offset %d (%x)",i,i];
        INTEXPECT(loadPtr(),dataptr+(i*sizeof(long)),msg);
    }
}

+(void)testADRPGeneration
{
    STObjectCodeGeneratorARM *gen=[self stream];
    unsigned int adrp1=[gen adrpForRegister:0 address:0 pc:0];
    HEXEXPECT(adrp1,0x90000000,@"no offset register 0");    // 1001
    unsigned int adrp2=[gen adrpForRegister:0 address:4096 pc:0];
    HEXEXPECT(adrp2,0xb0000000,@"one page offset ");        // 1011
    unsigned int adrp3=[gen adrpForRegister:0 address:8192 pc:0];
    HEXEXPECT(adrp3,0xd0000000,@"two page offset ");        // 1101
    unsigned int adrp4=[gen adrpForRegister:0 address:8192+4096 pc:0];
    HEXEXPECT(adrp4,0xf0000000,@"three page offset ");        // 1111
    unsigned int adrp5=[gen adrpForRegister:0 address:16384 pc:0];
    HEXEXPECT(adrp5,0x90000020,@"four page offset ");        // 1001   --
    unsigned int adrp6=[gen adrpForRegister:0 address:0 pc:4096];
    HEXEXPECT(adrp6,0xf0ffffe0,@"negative one page offset ");        // 1111   --
//    unsigned int adrp7=[gen adrpForRegister:0 address:0 pc:5000 page_offset:&page_offset];
//    HEXEXPECT(adrp7,0xf0ffffe0,@"negative one page offset ");        // 1001   --
}

+(void)testLoadEmbeddedPointer
{
    VOIDPTR loadFromPtr = (VOIDPTR)[self fnFor:^(STObjectCodeGeneratorARM *gen) {
        [gen loadRegister:0 withEmbeddedPointer:(void*)0x123456789abcdef];
        
    }];
    INTEXPECT(loadFromPtr(),0x123456789abcdef,@"embedded answer");
}

+(NSArray*)testSelectors
{
   return @[
       @"testGenerateReturn",
       @"testGenerateAdd",
       @"testGenerateImmediateAdd",
       @"testGenerateImmediateSub",
       @"testGenerateSub",
       @"testGenerateMul",
       @"testGenerateSubReverseOrder",
       @"testGenerateStoreMultiple",
       @"testGenerateAddImmediate",
       @"testGenerateSubImmediate",
       @"testGenerateLoadPCRelative",
       @"testReserveStackSpace",
       @"testGenerateLoadMultiple",
       @"testGenerateDereferencePointerPassedIn",
       @"testGenerateSubtractPointedAtLongs",
       @"testGenerateCodeWithEmbeddedPointer",
       @"testGenerateBranchToPointerPassedAsArg",
       @"testGenerateCallToPointerPassedAsArg",
       @"testCanGenerateReturnAddressProtection",
//       @"testJITMessageSendAndComputation",
//       @"testJITLengthOfPassedStringPlus3",
       @"testADRPGeneration",
//    @"testEmbeddedPointerGenerationOverRange",
       @"testLoadEmbeddedPointer",
			];
}

@end
