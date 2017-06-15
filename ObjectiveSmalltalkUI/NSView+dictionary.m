//
//  NSView+dictionary.m
//  ObjectiveSmalltalk
//
//  Created by Marcel Weiher on 6/15/17.
//
//

#import "NSView+dictionary.h"
#import <MPWFoundation/MPWFoundation.h>
#import <ObjectiveSmalltalk/MPWStCompiler.h>

@implementation NSView(dictionary)


-(instancetype)initWithDictionary:(NSDictionary *)dict
{
    NSRect frameRect=NSZeroRect;
    id frameObject=dict[@"frame"];
    if ( frameObject ) {
        frameRect=[frameObject rectValue];
    }
    self=[self initWithFrame:frameRect];
    for ( NSString *key in [dict allKeys]) {
        if ( ![key isEqualToString:@"frame"]) {
            [self setValue:dict[key] forKey:key];
        }
    }
    return self;
}

@end


@interface NSViewFromDictTesting : NSView {}
@end

@implementation NSViewFromDictTesting

+(void)testCanCreateBasicViewFromDictionary
{
    NSView *v=[[[NSView alloc] initWithDictionary:@{}] autorelease];
    EXPECTNOTNIL(v, @"got a view");
    FLOATEXPECT(v.frame.origin.x, 0, @"zerorect x");
    FLOATEXPECT(v.frame.origin.y, 0, @"zerorect y");
    FLOATEXPECT(v.frame.size.width, 0, @"zerorect width");
    FLOATEXPECT(v.frame.size.height, 0,@"zerorect height");
}

+(void)testCanCreateBasicViewFromST
{
    NSView *v=[MPWStCompiler evaluate:@" #NSView{} "];
    EXPECTNOTNIL(v, @"got a view");
    EXPECTTRUE( [v isKindOfClass:[NSView class]],@"is a view");
    FLOATEXPECT(v.frame.origin.x, 0, @"zerorect x");
    FLOATEXPECT(v.frame.origin.y, 0, @"zerorect y");
    FLOATEXPECT(v.frame.size.width, 0, @"zerorect width");
    FLOATEXPECT(v.frame.size.height, 0,@"zerorect height");
}



+(void)testCanSpecifyFrame
{
    NSView *v=[MPWStCompiler evaluate:@" #NSView{ #frame : ( 10@20 extent: 400@200) } "];
    EXPECTNOTNIL(v, @"got a view");
    EXPECTTRUE( [v isKindOfClass:[NSView class]],@"is a view");
    FLOATEXPECT(v.frame.origin.x, 10, @"zerorect x");
    FLOATEXPECT(v.frame.origin.y, 20, @"zerorect y");
    FLOATEXPECT(v.frame.size.width, 400, @"zerorect width");
    FLOATEXPECT(v.frame.size.height, 200,@"zerorect height");
}



+testSelectors
{
    return @[
             @"testCanCreateBasicViewFromDictionary",
             @"testCanCreateBasicViewFromST",
             @"testCanSpecifyFrame",
             ];
    
}

@end
