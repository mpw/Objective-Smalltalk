//
//  STPathToTemplateNameMapper.m
//  Sails
//
//  Created by Marcel Weiher on 05.03.24.
//

#import "STPathToTemplateNameMapper.h"


@implementation STPathToTemplateNameMapper

-(id)at:(id<MPWReferencing>)aReference
{
    NSString *path = [aReference path];
    if ( [path hasSuffix:@"/edit"]) {
        return [self.baseName stringByAppendingString:@"Edit.html"];
    } else if ( [path hasSuffix:@"new"]) {
        return [self.baseName stringByAppendingString:@"New.html"];
    } else if ( [aReference isRoot]) {
        return [self.baseName stringByAppendingString:@"List.html"];
    } else {
        return [self.baseName stringByAppendingString:@"Display.html"];
    }
}

@end


#import <MPWFoundation/DebugMacros.h>

@implementation STPathToTemplateNameMapper(testing) 

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
