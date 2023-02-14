//
//  MPWLiteralDictionaryExpression.m
//  ObjectiveSmalltalk
//
//  Created by Marcel Weiher on 1/22/17.
//
//

#import "MPWLiteralDictionaryExpression.h"
#import "STEvaluator.h"

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

-(NSDictionary*)dictionaryForLiteralInContext:(STEvaluator*)aContext class:(Class)dictClass
{
#define MAXSTACK 50
    id stackKeys[MAXSTACK];
    id stackValues[MAXSTACK];
    id *keys=NULL;
    id *values=NULL;
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
        if ( values[i]==nil) {
            values[i]=[NSNull null];
            [NSException raise:@"nil" format:@"in literal expression class %@ key:%@ value:%@",self.literalClassName,keys[i],values[i]];
        }
    }
    NSDictionary *result=[dictClass dictionaryWithObjects:values forKeys:keys count:maxKeyVal];
    if ( keys != stackKeys) {
        free(keys);
    }
    if ( values != stackValues) {
        free(values);
    }
    return result;

}



-(id)evaluateIn:(id)aContext
{
//    NSLog(@"evaluate literal dict: %@",self);
    MPWScheme *templates=[aContext schemeForName:@"template"];
    Class baseClass=[NSDictionary class];
    id factory=[self factoryForContext:aContext];
    NSMutableDictionary *baseDictionary=nil;
    MPWLiteralDictionaryExpression *template = [templates at:self.literalClassName];
    if ( template ) {
        factory=[template factoryForContext:aContext];
        baseDictionary=(NSMutableDictionary*)[template dictionaryForLiteralInContext:aContext class:[NSMutableDictionary class]];
    }
    if ( self.literalClassName && !factory ) {
        [NSException raise:@"classnotfound" format:@"Class '%@ not found in literal object expression",self.literalClassName];
    }

//    NSLog(@"evaluated: %@",evaluated);
    if ( [factory respondsToSelector:@selector(dictionaryWithObjects:forKeys:count:)]) {
        baseClass=factory;
    }
    NSDictionary *params=[self dictionaryForLiteralInContext:aContext class:baseClass];
    id result=params;
    if ( baseDictionary.count) {
        [baseDictionary addEntriesFromDictionary:params];
        params=baseDictionary;
    }
    
    if ( factory && factory != baseClass && [factory instancesRespondToSelector:@selector(initWithDictionary:)]) {
        result=[[[factory alloc] initWithDictionary:params] autorelease];
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
