//
//  MPWLiteralDictionaryExpression.m
//  ObjectiveSmalltalk
//
//  Created by Marcel Weiher on 1/22/17.
//
//

#import "MPWLiteralDictionaryExpression.h"
#import "MPWEvaluator.h"

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

-(void)setClassName:(NSString *)name
{
    self.literalClassName=name;
}

-(id <MPWStorage>)builderForContext:(MPWEvaluator*)aContext
{
    return [aContext schemeForName:@"builder"];
}

-(Class)classForContext:(MPWEvaluator*)aContext
{
    id <MPWStorage> builder = [self builderForContext:aContext];
    NSAssert2(builder!= nil, @"builder for context: %@ schemes: %@",aContext,[aContext schemeForName:@"scheme"]);
    NSString *className = self.literalClassName;
    if (!className) {
        className = @"NSMutableDictionary";
    }
//    Class finalClass=self.literalClass;
    Class finalClass=[builder at:className];
    if (!finalClass) {
        NSLog(@"builder %@ from context %@ did not deliver a class for name '%@'",builder,aContext,className);
        finalClass=[NSMutableDictionary class];
    }
    return finalClass;
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
    Class finalClass=[self classForContext:aContext];

    unsigned long maxKeyVal=MIN(self.keys.count,self.values.count);
    if ( maxKeyVal > MAXSTACK ) {
        keys=malloc( maxKeyVal * sizeof(id));
        keys=malloc( maxKeyVal * sizeof(id));
    } else {
        keys=stackKeys;
        values=stackValues;
    }
    [self.keys getObjects:keys range:NSMakeRange(0, maxKeyVal)];
    [self.values getObjects:values range:NSMakeRange(0, maxKeyVal)];
    
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
