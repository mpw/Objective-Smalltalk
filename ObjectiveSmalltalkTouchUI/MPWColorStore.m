//
//  MPWColorStore.m
//  ObjectiveSmalltalkTouchUI
//
//  Created by Marcel Weiher on 25.01.21.
//

#import "MPWColorStore.h"
@import UIKit;

@implementation MPWColorStore

-(id)at:(id<MPWReferencing>)aReference
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
