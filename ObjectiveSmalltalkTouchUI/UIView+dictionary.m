//
//  UIView+dictionary.m
//  ObjectiveSmalltalkTouch
//
//  Created by Marcel Weiher on 20.01.21.
//

#import "UIView+dictionary.h"
#import <MPWFoundation/MPWFoundation.h>
 
@implementation UIView(dictionary)

-(void)addSubviews:(NSArray *)views
{
    for ( UIView *view in views ) {
        [self addSubview:view];
    }
}

-(instancetype)initWithDictionary:(NSDictionary *)dict
{
    NSRect frameRect=NSZeroRect;
    id frameObject=dict[@"frame"];
    if ( frameObject ) {
        frameRect=[[frameObject asRect] rectValue];
    }
    self=[self initWithFrame:frameRect];
    for ( NSString *key in [dict allKeys]) {
        if ( ![key isEqualToString:@"frame"] && ![key isEqualToString:@"views"]) {
            [self setValue:dict[key] forKey:key];
        }
    }
    [self addSubviews:dict[@"views"]];
    return self;
}

@end

@implementation UIStackView(addViews)

-(void)addSubviews:(NSArray*)views
{
    for ( UIView *view in views ) {
        [self addArrangedSubview:view];
    }
}

@end

@interface UIViewDictionaryInitializationTests:NSObject
{
}
@end

@implementation UIViewDictionaryInitializationTests

+(void)testFrameRectMapping
{
    UIView *v=[[UIView alloc] initWithDictionary:@{ @"frame": @(3) }];
    CGRect r=[v frame];
    FLOATEXPECT(r.origin.x, 0, @"x");
    FLOATEXPECT(r.origin.y, 0, @"y");
    FLOATEXPECT(r.size.width, 3, @"width");
    FLOATEXPECT(r.size.height, 3, @"height");
    v=[[UIView alloc] initWithDictionary:@{ @"frame": [MPWPoint pointWithX:100 y:20] }];
    r=[v frame];
    FLOATEXPECT(r.origin.x, 0, @"x");
    FLOATEXPECT(r.origin.y, 0, @"y");
    FLOATEXPECT(r.size.width, 100, @"width");
    FLOATEXPECT(r.size.height, 20, @"height");

}

+testSelectors
{
    return @[
        @"testFrameRectMapping",
    ];
}

@end
