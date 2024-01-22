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


-(instancetype)initWithPropertyPaths:(PropertyPathDef*)newPaths count:(int)count verb:(MPWRESTVerb)verb
{
    static struct {
        MPWRESTVerb verb;
        int         numExtraParams;
        NSString    *declstring;
    } defaults[] = {
        {MPWRESTVerbGET, 1,@"at:aReference" },
        {MPWRESTVerbPUT, 2,@"<void>at:aReference put:newValue"},
        {MPWRESTVerbPOST, 2,@"<void>at:aReference post:newValue"},
    };
    if ( self=[super init] ) {
        int whichDefault=-1;
        for (int i=0;i<3;i++) {
            if ( verb == defaults[i].verb) {
                whichDefault=i;
                break;
            }
        }
        NSAssert1(whichDefault>=0, @"unsupported REST Verb: %d",verb);
        
        self.store = [[[MPWTemplateMatchingStore alloc] initWithPropertyPathDefs:newPaths count:count] autorelease];
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

