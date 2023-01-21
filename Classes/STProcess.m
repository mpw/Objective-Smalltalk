//
//  STProcess.m
//  ObjSTNative
//
//  Created by Marcel Weiher on 16.01.23.
//

#import "STProcess.h"
#import <MPWFoundation/MPWFoundation.h>


@interface STProcess()

@property (nonatomic,strong ) NSString *name;

@end

@implementation STProcess


@end


#import <MPWFoundation/DebugMacros.h>

@implementation STProcess(testing) 


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


int runSTMain( int argc, char *argv[], NSString *className ) {
    
    if (!className) {
        className=@"STProcess";
    }
    Class theClass = NSClassFromString(className);
    return [theClass mainArgc:argc argv:argv];
    
}

@implementation NSObject(stprocess)


-main:args
{
    return @(0);
}

-Stdout
{
    return [MPWByteStream Stdout];
}

+(int)main:(NSArray <NSString*>*)args
{
    STProcess *process=[[self new] autorelease];
    if ( args.count > 0) {
        process.name = [args firstObject];
        args = [args subarrayWithRange:NSMakeRange(1,args.count-1)];
    }
    int retval = [[process main:args] intValue];
    [process release];
    return retval;
}

+(int)mainArgc:(int)argc argv:(char**)argv
{
    NSMutableArray *args=[NSMutableArray array];
    for (int i=0;i<argc;i++) {
        [args addObject:@(argv[i])];
    }
    return [self main:args];
}

@end
