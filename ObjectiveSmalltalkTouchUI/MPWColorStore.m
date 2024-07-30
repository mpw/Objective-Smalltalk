//
//  MPWColorStore.m
//  ObjectiveSmalltalkTouchUI
//
//  Created by Marcel Weiher on 25.01.21.
//

#import "MPWColorStore.h"
@import UIKit;

@implementation MPWColorStore

-(id)at:(id<MPWIdentifying>)aReference
{
    NSString* name=[aReference path];
    NSString *msg=[name stringByAppendingString:@"Color"];
    SEL sel=NSSelectorFromString(msg);
    if ( sel && [UIColor respondsToSelector:sel]) {
        return [UIColor performSelector:sel];
    }
    return nil;
}

@end

@implementation MPWColorStore(testing)

+(void)testBasicColors
{
    MPWColorStore *store=[self store];
    IDEXPECT(store[@"red"], [UIColor redColor],  @"red");
    IDEXPECT(store[@"green"], [UIColor greenColor],  @"green");
    IDEXPECT(store[@"white"], [UIColor whiteColor],  @"white");
}

+(NSArray*)testSelectors
{
    return @[
        @"testBasicColors",
    ];
}

@end
