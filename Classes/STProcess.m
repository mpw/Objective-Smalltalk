//
//  STProcess.m
//  ObjSTNative
//
//  Created by Marcel Weiher on 16.01.23.
//

#import "STProcess.h"

@interface STProcess()

@property (nonatomic,strong ) NSString *name;

@end

@implementation STProcess

-(int)main:args
{
    return 0;
}

+(int)main:(NSArray <NSString*>*)args
{
    NSLog(@"+main args=%@",args);
    STProcess *process=[[self new] autorelease];
    if ( args.count > 0) {
        process.name = [args firstObject];
        args = [args subarrayWithRange:NSMakeRange(1,args.count-1)];
    }
    int retval = [process main:args];
    [process release];
    return retval;
}

+(int)mainArgc:(int)argc argv:(char**)argv
{
    NSLog(@"mainArgc:argc=%d argv=%p",argc,argv);
    NSMutableArray *args=[NSMutableArray array];
    for (int i=0;i<argc;i++) {
        [args addObject:@(argv[i])];
    }
    NSLog(@"args=%@",args);
    return [self main:args];
}

@end


#import <MPWFoundation/DebugMacros.h>

@implementation STProcess(testing) 

int runSTMain( int argc, char *argv[], NSString *className ) {
    NSLog(@"runSTMain");
    NSLog(@"argc: %d",argc);
    NSLog(@"argv: %p",argv);
    NSLog(@"className: %p",className);
    NSLog(@"className: %@",className);

    if (!className) {
        className=@"STProcess";
    }
    NSLog(@"className: %@",className);
    Class theClass = NSClassFromString(className);
    NSLog(@"theClass: %@",theClass);
    return (int)[theClass mainArgc:argc argv:argv];

}

+(void)someTest
{
	EXPECTTRUE(false, @"implemented");
}

+(NSArray*)testSelectors
{
   return @[
//			@"someTest",
			];
}

@end
