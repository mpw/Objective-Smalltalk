//
//  MPWARMAssemblyGenerator.m
//  ObjSTNative
//
//  Created by Marcel Weiher on 04.12.20.
//

#import "MPWARMAssemblyGenerator.h"

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


-(void)mov:(int)regNo value:(long)value
{
    [self printf:@"\tmov\tX%d, #%ld\n",regNo,value];
}

-(void)ret
{
    [self printf:@"\tret\n"];
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

+(NSArray*)testSelectors
{
   return @[
       @"testGenerateLabel",
       @"testGenerateMove",
			];
}

@end
