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

-(NSDictionary*)computeNameMap
{
    NSString *names=UIFont.familyNames;
    NSMutableDictionary *theMap=[NSMutableDictionary dictionary];
    for ( NSString *name in names ) {
        if ( [name containsString:@" "]) {
            NSString *mapped=[name stringByReplacingOccurrencesOfString:@" " withString:@"" options:0 range:NSMakeRange(0,name.length)];
            theMap[mapped]=name;
        }
    }
    return theMap;
}

-(instancetype)init
{
    self=[super init];
    self.nameMap = [self computeNameMap];
    return self;
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
            NSString *name=path[0];
            NSString *mapped=self.nameMap[name];
            if ( mapped ) {
                name=mapped;
            }
            return [UIFont fontWithName:name size:[path[1] floatValue]];
        }
    } else if ( [aReference isRoot] || path.count ==0 || (path.count == 1 && [path.firstObject isEqual:@"."] )) {
        return UIFont.familyNames;
    }
    return nil;
}


@end
