//
//  MPWLiteralDictionaryExpression.m
//  ObjectiveSmalltalk
//
//  Created by Marcel Weiher on 1/22/17.
//
//

#import "MPWLiteralDictionaryExpression.h"

@interface MPWLiteralDictionaryExpression ()

@property (nonatomic, strong)  NSMutableArray *keys;
@property (nonatomic, strong)  NSMutableArray *values;


@end

@implementation MPWLiteralDictionaryExpression


-(instancetype)init
{
    self=[super init];
    self.keys=[NSMutableArray array];
    self.values=[NSMutableArray array];
    return self;
}

-(void)addKey:key value:value
{
    [self.keys addObject:key];
    [self.values addObject:value];
}

-(id)evaluateIn:(id)aContext
{
//    NSLog(@"evaluate literal dict: %@",self);
    NSMutableDictionary *evaluated=[NSMutableDictionary dictionaryWithCapacity:self.keys.count];
    for (int i=0;i<self.keys.count;i++) {
        evaluated[[self.keys[i] evaluateIn:aContext]]=[self.values[i] evaluateIn:aContext];
    }
//    NSLog(@"evaluated: %@",evaluated);
    return evaluated;
}

-(void)dealloc
{
    [_keys release];
    [_values release];
    [super dealloc];
}

@end
