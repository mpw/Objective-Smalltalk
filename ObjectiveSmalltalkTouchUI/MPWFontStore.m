//
//  MPWFontStore.m
//  ObjectiveSmalltalkTouchUI
//
//  Created by Marcel Weiher on 26.01.21.
//

#import "MPWFontStore.h"
#import <ObjectiveSmalltalk/MPWGlobalVariableStore.h>

@import UIKit;


@implementation MPWFontStore {
    NSDictionary *styles;
}

-(NSDictionary*)createStyles
{
    NSMutableDictionary *constructionStyles=[NSMutableDictionary dictionary];
    MPWGlobalVariableStore *globals=[MPWGlobalVariableStore store];
    NSArray *shortNames=@[
        @"body",
        @"callout",
        @"caption1",
        @"caption2",
        @"footnote",
        @"headline",
        @"subheadline",
        @"largeTitle",
        @"title1",
        @"title2",
        @"title3",
    ];
    for ( NSString *styleName in shortNames) {
        NSString *capitalized = [[[styleName substringToIndex:1] uppercaseString] stringByAppendingString:[styleName substringFromIndex:1]];
        // Note:  -capitalizedString does not work here as it messes up internal capitalization
        NSString *longName = [@"UIFontTextStyle" stringByAppendingString:capitalized];
        NSString *value = [globals at:[globals referenceForPath:longName]];
        if ( styleName && value ) {
            constructionStyles[styleName]=value;
        }
    }
    return [constructionStyles copy];
}

lazyAccessor(NSDictionary, styles, setStyles, createStyles)

-(id)at:(id<MPWReferencing>)aReference
{
    NSArray<NSString*> *path=[aReference relativePathComponents];
    if ( path.count == 2 ) {
        if ( [path[0] isEqual:@"style"]) {
            NSString *style=path[1];
            NSString *mappedStyle=[self styles][style];
            if ( mappedStyle) {
                return [UIFont preferredFontForTextStyle:mappedStyle];
            } else {
                return nil;
            }
        } else {
            return [UIFont fontWithName:path[0] size:[path[1] floatValue]];
        }
    }
    return nil;
}


@end
