//
//  MPWARMAssemblyGenerator.m
//  ObjSTNative
//
//  Created by Marcel Weiher on 04.12.20.
//

#import "MPWARMAssemblyGenerator.h"

#define SP   -1

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

-(void)outputRegister:(int)regno
{
    if ( regno == SP ) {
        [self printf:@"SP"];
    } else {
        [self printf:@"X%d",regno];
    }
}


-(void)outputInstruction:(NSString*)instruction regNo:(int)regNo value:(long)value
{
    [self printFormat:@"\t%@\t",instruction];
    [self outputRegister:regNo];
    [self printf:@", #%ld\n",value];
}

-(void)mov:(int)regNo value:(long)value
{
    [self outputInstruction:@"mov" regNo:regNo value:value];
}

-(void)svc:(int)vector
{
    [self printFormat:@"\tsvc\t#%ld\n",vector];
}

-(void)ret
{
    [self printf:@"\tret\n"];
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

+(void)testGenerateASCIZ
{
    MPWARMAssemblyGenerator *g=[self stream];
    [g asciiz:@"Hello World"];
    IDEXPECT( [[g target] stringValue], @"\t.asciz\t\"Hello World\"\n",@"string");
}

+(NSArray*)testSelectors
{
   return @[
       @"testGenerateLabel",
       @"testGenerateMove",
       @"testGenerateSPMove",
       @"testGenerateASCIZ",
			];
}

@end
