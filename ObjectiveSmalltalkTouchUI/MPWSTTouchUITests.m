//
//  MPWSTTouchUITests.m
//  ObjectiveSmalltalkTouchUI
//
//  Created by Marcel Weiher on 28.02.21.
//

#import "MPWSTTouchUITests.h"
#import "MPWFontStore.h"
#import <UIKit/UIKit.h>


@implementation MPWSTTouchUITests

@end


#import <MPWFoundation/DebugMacros.h>

@implementation MPWSTTouchUITests(testing) 

+(void)testGetFontViaStore
{
    MPWFontStore *fonts=[MPWFontStore store];
    UIFont *f=[fonts at:@"Helvetica/12"];
    FLOATEXPECT(f.pointSize, 12, @"font size");
    IDEXPECT(f.fontName, @"Helvetica", @"font name");
}

+(NSArray*)testSelectors
{
   return @[
			@"testGetFontViaStore",
			];
}

@end
