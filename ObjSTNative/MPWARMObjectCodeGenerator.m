//
//  MPWARMObjectCodeGenerator.m
//  ObjSTNative
//
//  Created by Marcel Weiher on 04.09.22.
//
//  http://kitoslab-eng.blogspot.com/2012/10/armv8-aarch64-instruction-encoding.html
//

#import "MPWARMObjectCodeGenerator.h"

@implementation MPWARMObjectCodeGenerator

-defaultTarget
{
        
}


-(NSData*)generatedCode
{
    long targetLen=16384;
    NSData *written=[self target];
    char *executableBytes=mmap(NULL, 16384, PROT_WRITE|PROT_READ, MAP_ANON|MAP_PRIVATE, 0, 0);
    if (  executableBytes != MAP_FAILED && written ) {
        NSLog(@"executableBytes: %p",executableBytes);
        long length = written.length;
        long toCopy = MIN(length,targetLen);
        NSLog(@"length=%ld, source=%p target=%p",toCopy,written.bytes,executableBytes);
        memcpy(executableBytes, written.bytes, MIN(length,targetLen));
        int retcode = mprotect(executableBytes, targetLen, PROT_READ|PROT_EXEC);
        NSLog(@"return of mprotect: %d errno: %d",retcode,errno);
        return [[NSData dataWithBytesNoCopy:executableBytes length:toCopy] retain];
    } else {
        NSLog(@"mmap failed: %s",strerror(errno));
        return nil;
    }
}

-(IMP)code
{
    return [[self target] bytes];
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

-(void)generateAdd
{
    // hard coded:  X0 = X0 + X1
    [self appendWord32:0x8b010000];
}


@end



#import <MPWFoundation/DebugMacros.h>

@implementation MPWARMObjectCodeGenerator(testing) 

+(void)testGenerateReturn
{
    MPWARMObjectCodeGenerator *g=[self stream];
    [g generateReturn];
    NSData *code=[g generatedCode];
    INTEXPECT(code.length,4,@"length of generated code");
    IMP fn=(IMP)[code bytes];
    EXPECTTRUE(true, @"before call");
    fn();
    EXPECTTRUE(true, @"got here");
}

typedef long (*IMPINTINT)(long, long);


+(void)testGenerateAdd
{
    MPWARMObjectCodeGenerator *g=[self stream];
    [g generateAdd];
    [g generateReturn];
    NSData *code=[g generatedCode];
    INTEXPECT(code.length,8,@"length of generated code");
    IMPINTINT addfn=(IMPINTINT)[code bytes];
    EXPECTTRUE(true, @"before call")
    long result=addfn(3,4);
    EXPECTTRUE(true, @"got here");
    INTEXPECT(result,7,@"3+4");    
}



+(NSArray*)testSelectors
{
   return @[
       @"testGenerateReturn",
       @"testGenerateAdd",
			];
}

@end
