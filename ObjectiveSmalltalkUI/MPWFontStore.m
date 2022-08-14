//
//  MPWFontStore.m
//  ObjectiveSmalltalkUI
//
//  Created by Marcel Weiher on 07.03.21.
//

#import "MPWFontStore.h"
#import <AppKit/AppKit.h>
#import "MPWGlobalVariableStore.h"

@interface MPWFontStore()

@property (nonatomic,strong) NSDictionary *nameMap;

@end

@implementation MPWFontStore {
NSDictionary *styles;
}

-(NSDictionary*)computeNameMap
{
    NSString *names=[[NSFontManager sharedFontManager] availableFontFamilies];
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
//    self.nameMap = [self computeNameMap];
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
        NSString *longName = [@"NSFontTextStyle" stringByAppendingString:capitalized];
        NSString *value = [globals at:[globals referenceForPath:longName]];
        if ( styleName && value ) {
            constructionStyles[styleName]=value;
        }
    }
    return [constructionStyles copy];
}

lazyAccessor(NSDictionary*, styles, setStyles, createStyles)

-(id)at:(id<MPWReferencing>)aReference
{
    NSArray<NSString*> *path=[aReference relativePathComponents];
    if ( path.count == 2 ) {
        
        if ( [path[0] isEqual:@"style"]) {
            NSString *style=path[1];
            NSString *mappedStyle=[self styles][style];
            if ( mappedStyle) {
                return [NSFont preferredFontForTextStyle:mappedStyle options:@{}];
            } else {
                return nil;
            }
        } else {
            NSString *name=path[0];
            NSString *mapped=self.nameMap[name];
            if ( mapped ) {
                name=mapped;
            }
            return [NSFont fontWithName:name size:[path[1] floatValue]];
        }
    } else if ( [aReference isRoot] || path.count ==0 || (path.count == 1 && [path.firstObject isEqual:@"."] )) {
        return [[NSFontManager sharedFontManager] availableFontFamilies];
    }
    return nil;
}

@end


#import <MPWFoundation/DebugMacros.h>

@implementation MPWFontStore(testing) 

+(void)testFontByName
{
    MPWFontStore *fonts=[self store];
    IDEXPECT( fonts[@"Helvetica/15"], [NSFont fontWithName:@"Helvetica" size:15], @"Helvetica 15pt");
}

+(void)testFontByNameWithSpacesRemoved
{
    MPWFontStore *fonts=[self store];
    IDEXPECT( fonts[@"AlNile/23"], [NSFont fontWithName:@"Al Nile" size:23], @"Al Nile 23pt");
}

+(void)testSystemFont
{
    MPWFontStore *fonts=[self store];
    IDEXPECT( fonts[@"style/caption1"], [NSFont preferredFontForTextStyle:NSFontTextStyleCaption1 options:@{}], @"caption font");
}


+(NSArray*)testSelectors
{
    return @[
        @"testFontByName",
        @"testFontByNameWithSpacesRemoved",
        @"testSystemFont",
    ];
}

@end
