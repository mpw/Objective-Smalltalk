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

+testSelectors
{
    return @[
    ];
}

@end
