//
//  MPWJavaScriptGenerator.m
//  ObjectiveSmalltalk
//
//  The Objective-J (Cappuccino) backend.  Objective-J source IS Objective-C syntax
//  ([recv sel:], @implementation … @end, - (id)method { … }) — it is the INPUT to
//  the Objective-J compiler, not the objj_msgSend runtime JavaScript the compiler
//  emits.  So this is a thin sibling of MPWObjCGenerator: it inherits all of the
//  Objective-C-family source emission from MPWLanguageGenerator and overrides only
//  the dialect deltas — NS* → CP* class names and the @import directive.
//
//  NB the class is still named MPWJavaScriptGenerator for historical reasons; it
//  produces Objective-J source, not JavaScript.  A rename is a mechanical follow-up.
//

#import "STObjJGenerator.h"

@implementation STObjJGenerator

+(NSString*)standardImports
{
    return @"@import <Foundation/CPObject.j>\n\n";
}

// Objective-J's class library mirrors Foundation with a CP prefix: NSString→CPString,
// NSObject→CPObject, NSDictionary→CPDictionary, …
-(NSString*)mapClassName:(NSString*)className
{
    if ( [className hasPrefix:@"NS"] ) {
        return [@"CP" stringByAppendingString:[className substringFromIndex:2]];
    }
    return className;
}

@end
