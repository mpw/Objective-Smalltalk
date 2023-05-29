//
//  MPWDyLibScheme.m
//  ObjSTNative
//
//  Created by Marcel Weiher on 29.05.23.
//

#import "MPWDyLibScheme.h"
#import <dlfcn.h>

@interface MPWDyLib : NSObject  {
    void *handle;
}

@property (nonatomic, strong) NSString *path;

-(instancetype)initWithPath:(NSString*)newPath;
-(BOOL)load;

@end

@implementation MPWDyLib

-(instancetype)initWithPath:(NSString*)newPath
{
    self=[super init];
    self.path=newPath;
    return self;
}

-(BOOL)loaded
{
    return handle != NULL;
}

-(BOOL)load
{
    if ( !handle ) {
        handle=dlopen( [self.path UTF8String], RTLD_NOW );
    }
    return [self loaded];
}

-at:(NSString*)symbol
{
    return [NSValue valueWithPointer:dlsym(handle, [symbol UTF8String])];
}

-(NSString*)description
{
    return [NSString stringWithFormat:@"<DyLib: %@ %@loaded>",self.path,[self loaded]?@"":@"not "];
}

@end


@implementation MPWDyLibScheme

-(id)at:(id<MPWReferencing>)aReference
{
    return [[[MPWDyLib alloc] initWithPath:[aReference path]] autorelease];
}

@end


#import <MPWFoundation/DebugMacros.h>

@implementation MPWDyLibScheme(testing) 

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
