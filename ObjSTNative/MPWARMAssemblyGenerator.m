//
//  MPWARMAssemblyGenerator.m
//  ObjSTNative
//
//  Created by Marcel Weiher on 04.12.20.
//

#import "MPWARMAssemblyGenerator.h"

#define SP   -1
#define LR   30
#define FP   29

@implementation MPWARMAssemblyGenerator

-(void)label:(NSString*)label
{
    [self outputString:label];
    [self printf:@":\n"];
}

-(void)directive:(NSString*)directive arg:arg
{
    [self printFormat:@".%@\t%@\n",directive,[arg stringValue]];
}

-(void)global:(NSString*)label
{
    [self directive:@"global" arg:label];
}

-(void)align:(int)alignment
{
    [self directive:@"align" arg:@(alignment)];
}

//---- utilities

-(void)outputRegister:(int)regno
{
    if ( regno == SP ) {
        [self printf:@"SP"];
    } else if ( regno == LR ) {
        [self printf:@"LR"];
    } else{
        [self printf:@"X%d",regno];
    }
}


-(void)instruction:(NSString*)instruction regNo:(int)regNo value:(long)value
{
    [self printFormat:@"\t%@\t",instruction];
    [self outputRegister:regNo];
    [self printf:@", #%ld\n",value];
}

-(void)instruction:(NSString*)instruction regNo:(int)destReg regNo:(int)sourceReg value:(long)value
{
    [self printFormat:@"\t%@\t",instruction];
    [self outputRegister:destReg];
    [self printf:@", "];
    [self outputRegister:sourceReg];
    [self printf:@", #%ld\n",value];
}

-(void)loadStore:(NSString*)instruction regNo:(int)destReg addressRegister:(int)sourceReg offset:(long)offset
{
    [self printFormat:@"\t%@\t",instruction];
    [self outputRegister:destReg];
    [self printf:@",["];
    [self outputRegister:sourceReg];
    if ( offset ) {
        [self printf:@",#%ld",offset];
    }
    [self printf:@"]\n"];
    
}

-(void)instruction:(NSString*)instruction value:(long)value
{
    [self printFormat:@"\t%@\t",instruction];
    [self printf:@"#%ld\n",value];
}

-(void)instruction:(NSString*)instruction
{
    [self printFormat:@"\t%@\n",instruction];

}

//---- specific instructions


-(void)mov:(int)regNo value:(long)value
{
    [self instruction:@"mov" regNo:regNo value:value];
}

-(void)svc:(int)vector
{
    [self instruction:@"svc" value:vector];
}

-(void)ret
{
    [self instruction:@"ret"];
}

-(void)bl:(NSString*)address
{
    [self printFormat:@"\tbl\t%@\n",address];
}

-(void)adr:(int)regNo address:(NSString*)address
{
    [self printFormat:@"\tadr\t"];
    [self outputRegister:regNo];
    [self printFormat:@", %@\n",address];
}

-(void)asciiz:(NSString*)str
{
    [self printFormat:@"\t.asciz\t\"%@\"\n",str];
}

-(void)add:(int)destReg sourceReg:(int)sourceReg sourceValue:(int)constant
{
    [self instruction:@"add" regNo:destReg regNo:sourceReg value:constant];
}

-(void)sub:(int)destReg sourceReg:(int)sourceReg sourceValue:(int)constant
{
    [self instruction:@"sub" regNo:destReg regNo:sourceReg value:constant];
}

-(void)ldr:(int)destReg addressRegister:(int)sourceReg offset:(int)constant
{
    [self loadStore:@"ldr" regNo:destReg addressRegister:sourceReg offset:constant];
}

-(void)str:(int)destReg addressRegister:(int)sourceReg offset:(int)constant
{
    [self loadStore:@"str" regNo:destReg addressRegister:sourceReg offset:constant];
}

-(void)stp:(int)destReg second:(int)second addressRegister:(int)sourceReg offset:(int)constant
{
    [self printFormat:@"\tstp\t"];
    [self outputRegister:destReg];
    [self printf:@","];
    [self outputRegister:second];
    [self printf:@",["];
    [self outputRegister:sourceReg];
    if ( constant ) {
        [self printf:@",#%d",constant];
    }
    [self printf:@"]\n"];
    
}

-(void)ldp:(int)destReg second:(int)second addressRegister:(int)sourceReg offset:(int)constant
{
    [self printFormat:@"\tldp\t"];
    [self outputRegister:destReg];
    [self printf:@","];
    [self outputRegister:second];
    [self printf:@",["];
    [self outputRegister:sourceReg];
    [self printf:@"]"];
    if ( constant ) {
        [self printf:@", #%d",constant];
    }
    [self printf:@"\n"];

}


@end


#import <MPWFoundation/DebugMacros.h>

@implementation MPWARMAssemblyGenerator(testing) 

+(void)testGenerateLabel
{
    MPWARMAssemblyGenerator *g=[self stream];
    [g label:@"hi"];
    IDEXPECT( [[g target] stringValue], @"hi:\n",@"label");
}

+(void)testGenerateMove
{
    MPWARMAssemblyGenerator *g=[self stream];
    [g mov:1 value:1234];
    IDEXPECT( [[g target] stringValue], @"\tmov\tX1, #1234\n",@"mov");
}

+(void)testGenerateSPMove
{
    MPWARMAssemblyGenerator *g=[self stream];
    [g mov:SP value:34];
    IDEXPECT( [[g target] stringValue], @"\tmov\tSP, #34\n",@"mov with SP");
}

+(void)testGenerateSVC
{
    MPWARMAssemblyGenerator *g=[self stream];
    [g svc:128];
    IDEXPECT( [[g target] stringValue], @"\tsvc\t#128\n",@"svc");
}

+(void)testGenerateASCIZ
{
    MPWARMAssemblyGenerator *g=[self stream];
    [g asciiz:@"Hello World"];
    IDEXPECT( [[g target] stringValue], @"\t.asciz\t\"Hello World\"\n",@"string");
}

+(void)testGenerateAdd
{
    MPWARMAssemblyGenerator *g=[self stream];
    [g add:1 sourceReg:2 sourceValue:12];
    IDEXPECT( [[g target] stringValue], @"\tadd\tX1, X2, #12\n",@"add");
}

+(void)testGenerateSub
{
    MPWARMAssemblyGenerator *g=[self stream];
    [g sub:SP sourceReg:SP sourceValue:16];
    IDEXPECT( [[g target] stringValue], @"\tsub\tSP, SP, #16\n",@"sub");
}

+(void)testGenerateLdr
{
    MPWARMAssemblyGenerator *g=[self stream];
    [g ldr:1 addressRegister:SP offset:16];
    IDEXPECT( [[g target] stringValue], @"\tldr\tX1,[SP,#16]\n",@"ldr");
}

+(void)testGenerateStr
{
    MPWARMAssemblyGenerator *g=[self stream];
    [g str:4 addressRegister:SP offset:24];
    IDEXPECT( [[g target] stringValue], @"\tstr\tX4,[SP,#24]\n",@"str");
}

+(void)testGenerateLdp
{
    MPWARMAssemblyGenerator *g=[self stream];
    [g ldp:1 second:2 addressRegister:SP offset:16];
    IDEXPECT( [[g target] stringValue], @"\tldp\tX1,X2,[SP], #16\n",@"ldp");
}

+(void)testGenerateStp
{
    MPWARMAssemblyGenerator *g=[self stream];
    [g stp:5 second:LR addressRegister:SP offset:-24];
    IDEXPECT( [[g target] stringValue], @"\tstp\tX5,LR,[SP,#-24]\n",@"str");
}

+(NSArray*)testSelectors
{
   return @[
       @"testGenerateLabel",
       @"testGenerateMove",
       @"testGenerateSPMove",
       @"testGenerateSVC",
       @"testGenerateASCIZ",
       @"testGenerateAdd",
       @"testGenerateSub",
       @"testGenerateLdr",
       @"testGenerateStr",
       @"testGenerateLdp",
       @"testGenerateStp",
			];
}

@end
