//
//  MPWColorStore.m
//  ObjectiveSmalltalkUI
//
//  Created by Marcel Weiher on 07.03.21.
//

#import "MPWColorStore.h"
#import <AppKit/AppKit.h>

@implementation MPWColorStore

-(id)at:(id<MPWIdentifying>)aReference
{
    NSString* name=[aReference path];
    NSString *msg=[name stringByAppendingString:@"Color"];
    SEL sel=NSSelectorFromString(msg);
    if ( sel && [NSColor respondsToSelector:sel]) {
        return [NSColor performSelector:sel];
    }
    return nil;
}

@end


#import <MPWFoundation/DebugMacros.h>

@implementation MPWColorStore(testing)

+(void)testBasicColors
{
    MPWColorStore *store=[self store];
    IDEXPECT(store[@"red"], [NSColor redColor],  @"red");
    IDEXPECT(store[@"green"], [NSColor greenColor],  @"green");
    IDEXPECT(store[@"white"], [NSColor whiteColor],  @"white");
}

+(NSArray*)testSelectors
{
    return @[
        @"testBasicColors",
    ];
}

@end
