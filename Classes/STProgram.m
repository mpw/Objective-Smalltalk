//
//  STProcess.m
//  ObjSTNative
//
//  Created by Marcel Weiher on 16.01.23.
//

#import "STProgram.h"
#import <MPWFoundation/MPWFoundation.h>
#import "MPWBlockContext.h"

@implementation STProgram

+(id)main:(NSArray <NSString*>*)args
{
    STProgram *process=[[self new] autorelease];
    if ( args.count > 0 && [process respondsToSelector:@selector(setName:)]) {
        process.name = [args firstObject];
        args = [args subarrayWithRange:NSMakeRange(1,args.count-1)];
    }
    // yes, the retain here is weird, but it appears to be necessary
    return [[process main:args] retain];
}


+(int)intMain:(NSArray <NSString*>*)args
{
    id retval = [self main:args];
    int retcode = [retval intValue];
    //  weird autorelease to balance out the weird retain above
    [retval autorelease];
    return retcode;
}

+(int)mainArgc:(int)argc argv:(char**)argv
{
    NSMutableArray *args=[NSMutableArray array];
    [MPWBlockContext class];            //
    for (int i=0;i<argc;i++) {
        [args addObject:@(argv[i])];
    }
    return [self intMain:args];
}

@end


#import <MPWFoundation/DebugMacros.h>

@implementation STProgram(testing) 


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



@interface STNonNilTestProgram : STProgram
@end

@implementation STNonNilTestProgram

+(int)main:(NSArray <NSString*>*)args
{
    STProgram *process=[[self new] autorelease];
    if ( args.count > 0 && [process respondsToSelector:@selector(setName:)]) {
        process.name = [args firstObject];
        args = [args subarrayWithRange:NSMakeRange(1,args.count-1)];
    }
    id retval = [process main:args];
    NSLog(@"object retval: %@",retval);
    NSAssert( retval != nil, @"retval should not be nil");
    int retcode = [retval intValue];
    [process release];
    return retcode;
}

@end
