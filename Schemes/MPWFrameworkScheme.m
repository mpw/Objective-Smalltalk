//
//  MPWFrameworkScheme.m
//  ObjectiveSmalltalk
//
//  Created by Marcel Weiher on 4/15/14.
//
//

#import "MPWFrameworkScheme.h"

@implementation MPWFrameworkScheme

-(NSArray *)basePaths
{
    return @[ @"/Library/Frameworks/",
              @"/System/Library/Frameworks/",
              ];
}

-valueForBinding:(MPWGenericBinding*)aBinding
{
    NSString *name=[aBinding name];
    NSBundle *result=nil;
    for ( NSString *base in [self basePaths]) {
        result=[NSBundle bundleWithPath:[[base stringByAppendingPathComponent:name] stringByAppendingPathExtension:@"framework"]];
        if ( result ) {
            break;
        }
    }
    return result;
}

@end
