//
//  NSView+dictionary.m
//  ObjectiveSmalltalk
//
//  Created by Marcel Weiher on 6/15/17.
//
//

#import "NSView+dictionary.h"
#import <MPWFoundation/MPWFoundation.h>
#import <ObjectiveSmalltalk/STCompiler.h>

@implementation NSView(dictionary)


-(instancetype)initWithDictionary:(NSDictionary *)dict
{
    NSRect frameRect=NSZeroRect;
    id frameObject=dict[@"frame"];
    if ( frameObject ) {
        frameRect=[[frameObject asRect] rectValue];
    }
    self=[self initWithFrame:frameRect];
    for ( NSString *key in [dict allKeys]) {
        if ( ![key isEqualToString:@"frame"] && ![key isEqualToString:@"subviews"] ) {
            [self setValue:dict[key] forKey:key];
        }
    }
    id subviews = dict[@"subviews"];
    if ( subviews ) {
        if ( [subviews isKindOfClass:[NSDictionary class]]) {
            NSDictionary *subviewDict=(NSDictionary*)subviews;
            for ( NSString *name in subviewDict.allKeys) {
                NSView *subview = subviewDict[name];
                subview.accessibilityIdentifier=name;
                [self addSubview:subview];
            }
        } else {
            [self setSubviews:subviews];
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
    NSView *v=[STCompiler evaluate:@" #NSView{} "];
    EXPECTNOTNIL(v, @"got a view");
    EXPECTTRUE( [v isKindOfClass:[NSView class]],@"is a view");
    FLOATEXPECT(v.frame.origin.x, 0, @"zerorect x");
    FLOATEXPECT(v.frame.origin.y, 0, @"zerorect y");
    FLOATEXPECT(v.frame.size.width, 0, @"zerorect width");
    FLOATEXPECT(v.frame.size.height, 0,@"zerorect height");
}



+(void)testCanSpecifyFrame
{
    NSView *v=[STCompiler evaluate:@" f := ( 10@20 extent: 400@200).  #NSView{ #frame: f } "];
    EXPECTNOTNIL(v, @"got a view");
    EXPECTTRUE( [v isKindOfClass:[NSView class]],@"is a view");
    FLOATEXPECT(v.frame.origin.x, 10, @"x");
    FLOATEXPECT(v.frame.origin.y, 20, @"y");
    FLOATEXPECT(v.frame.size.width, 400, @"width");
    FLOATEXPECT(v.frame.size.height, 200,@"height");
}

+(void)testCanSpecifyAdditionalValues
{
    NSView *v=[STCompiler evaluate:@" #NSView{ #alphaValue: 0.3 }"];
    FLOATEXPECT(v.alphaValue, 0.3, @"alpha");
}

+(void)testCanSpecifySubviewAsArray
{
    NSView *v=[STCompiler evaluate:@" #NSView{ #subviews:  #(   #NSView{ #alphaValue: 0.3 } ) }"];
    INTEXPECT( v.subviews.count, 1 ,@"number of subviews");
    EXPECTTRUE([v.subviews.firstObject isKindOfClass:[NSView class]], @"subview should be a view");
}

+(void)testCanSpecifySubviewAsDict
{
    NSView *v=[STCompiler evaluate:@" #NSView{ #subviews:  #{  #transparent:   #NSView{ #alphaValue: 0.3 } } }"];
    INTEXPECT( v.subviews.count, 1 ,@"number of subviews");
    EXPECTTRUE([v.subviews.firstObject isKindOfClass:[NSView class]], @"subview should be a view");
    IDEXPECT( v.subviews.firstObject.accessibilityIdentifier, @"transparent", @"name of subview" );
}

+(void)testCanSpecifySeveralSubviewsAsDict
{
    NSView *v=[STCompiler evaluate:@" #NSView{ #subviews:  #{  #transparent:   #NSView{ #alphaValue: 0.3 }, #opaque:  #NSView{ #alphaValue: 1.0 } } }"];
}


+testSelectors
{
    return @[
             @"testCanCreateBasicViewFromDictionary",
             @"testCanCreateBasicViewFromST",
             @"testCanSpecifyFrame",
             @"testCanSpecifyAdditionalValues",
             @"testCanSpecifySubviewAsArray",
             @"testCanSpecifySubviewAsDict",
             @"testCanSpecifySeveralSubviewsAsDict",
             ];
    
}

@end
