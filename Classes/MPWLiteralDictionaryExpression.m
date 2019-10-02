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
@property (nonatomic, assign)  Class literalClass;
@property (nonatomic, strong)  NSString *literalClassName;


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

-(void)setClassName:(NSString *)name
{
    self.literalClassName=name;
}

-(void)loadClass
{
    if ( self.literalClassName ) {
//        NSLog(@"set literal class name: '%@'",self.literalClassName);
        self.literalClass=NSClassFromString(self.literalClassName);
//        NSLog(@"literal class: %@",self.literalClass);
        if ( !self.literalClass) {
            [NSException raise:@"undefinedclass" format:@"Literal Class %@ undefined for dictionary literal",self.literalClassName];
        }
    }
}

-(id)evaluateIn:(id)aContext
{
//    NSLog(@"evaluate literal dict: %@",self);
#define MAXSTACK 20
    
    id stackKeys[MAXSTACK];
    id stackValues[MAXSTACK];
    id *keys=NULL;
    id *values=NULL;
    Class baseClass=[NSDictionary class];
    [self loadClass];
    Class finalClass=self.literalClass;

    unsigned long maxKeyVal=MIN(self.keys.count,self.values.count);
    if ( maxKeyVal > MAXSTACK ) {
        keys=malloc( maxKeyVal * sizeof(id));
        keys=malloc( maxKeyVal * sizeof(id));
    } else {
        keys=stackKeys;
        values=stackValues;
    }
    [self.keys getObjects:keys];
    [self.values getObjects:values];
    
    for (int i=0;i<maxKeyVal;i++) {
        keys[i]=[keys[i] evaluateIn:aContext];
        values[i]=[values[i] evaluateIn:aContext];
    }
//    NSLog(@"evaluated: %@",evaluated);
    if ( [finalClass respondsToSelector:@selector(dictionaryWithObjects:forKeys:count:)]) {
        baseClass=finalClass;
    }
    
    NSDictionary *result=[baseClass dictionaryWithObjects:values forKeys:keys count:maxKeyVal];
    
    if ( finalClass && finalClass != baseClass && [finalClass instancesRespondToSelector:@selector(initWithDictionary:)]) {
        result=[[[finalClass alloc] initWithDictionary:result] autorelease];
    }
    if ( keys != stackKeys) {
        free(keys);
    }
    if ( values != stackValues) {
        free(values);
    }
    return result;
}
        
-(void)dealloc
{
    [_keys release];
    [_values release];
    [super dealloc];
}

@end
