//
//  MPWPropertyPathGetter.m
//  ObjectiveSmalltalk
//
//  Created by Marcel Weiher on 8/26/18.
//

#import "MPWPropertyPathMethod.h"
#import <MPWFoundation/MPWFoundation.h>
#import <MPWFoundation/MPWReferenceTemplate.h>
#import <MPWFoundation/MPWTemplateMatchingStore.h>
#import "MPWPropertyPathDefinition.h"
#import "MPWMethodHeader.h"

@interface MPWPropertyPathMethod()

@property (nonatomic, assign) Class classOfMethod;
@property (nonatomic, strong) MPWTemplateMatchingStore *store;
@property (nonatomic, strong) NSString *declarationString;

@end

@implementation MPWPropertyPathMethod
{
    int         numExtraparams;
}
 
-(void)setupStoreWithPaths:(PropertyPathDefs*)newPaths
{
    for ( int i=0;i<newPaths->count;i++) {
        PropertyPathDef *def=&(newPaths->defs[i]);
        id method = def->method;
        if ( !method ) {
            if ( def->function){
                MPWFastInvocation *f=[MPWFastInvocation invocation];
                [f setIMP:def->function];
                method=f;
            } else {
                [NSException raise:@"undefined" format:@"No method defined for property path %@ (%d of %d) verb %d",def->propertyPath,i,newPaths->count,newPaths->verb];
              
            }
        }
        self.store[def->propertyPath] = method;
    }
//    for ( MPWPropertyPathDefinition *def in newPaths) {
//        if ( method ) {
//            self.store[def.propertyPath] = method;
//        } else {
//            @throw @"Should have been filtered before";
//        }
//    }
}



-(instancetype)initWithPropertyPaths:(PropertyPathDefs*)newPaths
{
    static struct {
        MPWRESTVerb verb;
        int         numExtraParams;
        NSString    *declstring;
    } defaults[] = {
        {MPWRESTVerbGET, 1,@"at:aReference" },
        {MPWRESTVerbPUT, 2,@"<void>at:aReference put:newValue"},
    };
    if ( self=[super init] ) {
        int whichDefault=-1;
        for (int i=0;i<2;i++) {
            if ( newPaths->verb == defaults[i].verb) {
                whichDefault=i;
                break;
            }
        }
        NSAssert1(whichDefault>=0, @"unsupported REST Verb: %d",newPaths->verb);
        
        self.store = [MPWTemplateMatchingStore store];
        [self setupStoreWithPaths:newPaths];
        self.methodHeader=[MPWMethodHeader methodHeaderWithString:defaults[whichDefault].declstring];
        numExtraparams = defaults[whichDefault].numExtraParams;
        self.declarationString = defaults[whichDefault].declstring;
    }
    return self;
}

-(id)evaluateOnObject:(id)target parameters:(NSArray *)parameters
{
    int numExtras=numExtraparams;
    id extraParameters[numExtras+2];
    [parameters getObjects:extraParameters range:NSMakeRange(0,numExtras)];
    id ref = extraParameters[0];
    return [self.store at:ref for:target with:extraParameters count:numExtras];
}

-(void)setContext:(id)newVar
{
    // compile-time context, needed when runtime doesn't
    // have a linked context because it was called from
    // Objective-C.
    [super setContext:newVar];
    [self.store setContext:newVar];
}

-(NSString*)script
{
    return @" 'property path'. ";
}

-(void)dealloc
{
    [_store release];
    [_declarationString release];
    [super dealloc];
}


@end
