//
//  STClassDefinition.m
//  ObjectiveSmalltalk
//
//  Created by Marcel Weiher on 4/12/17.
//
//

#import "STClassDefinition.h"
#import "NSObjectScripting.h"
#import "MPWMethodStore.h"
#import "MPWClassMethodStore.h"
#import "STCompiler.h"
#import "MPWPropertyPathMethod.h"
#import "STPropertyPathDefinition.h"
#import <MPWFoundation/MPWFoundation.h>

@interface NSObject(asReferenceTemplate)
-(MPWReferenceTemplate*)asReferenceTemplate;
@end


@implementation STClassDefinition


-(NSArray*)propertyPathDefinitionsForVerb:(MPWRESTVerb)verb
{
    NSMutableArray *ppdefs=[NSMutableArray array];
    for ( STPropertyPathDefinition *def in self.propertyPathDefinitions) {
        if ( [def methodForVerb:verb] ) {
            [ppdefs addObject:def];
        }
    }
    return ppdefs;
}

-(PropertyPathDefs*)propertyPathDefsForVerb:(MPWRESTVerb)thisVerb
{
    NSArray *definitions=[self propertyPathDefinitionsForVerb:thisVerb];
    int numDefinitions=(int)definitions.count;
    PropertyPathDefs *allDefs=NULL;
    if ( numDefinitions ) {
        PropertyPathDef *defs=calloc(numDefinitions, sizeof(PropertyPathDef));
        for (long j=0;j<numDefinitions;j++) {
            defs[j].function=NULL;
            defs[j].method = [[definitions[j] methodForVerb:thisVerb] retain];
            defs[j].propertyPath = [[[definitions[j] propertyPath] asReferenceTemplate] retain];
        }
        allDefs=makePropertyPathDefs(thisVerb ,numDefinitions, defs);
        free(defs);
    }
    return allDefs;
}

-(NSArray*)generatedPropertyPathMethods
{
    NSMutableArray *methods=[NSMutableArray array];
    MPWRESTVerb verbs[3]={ MPWRESTVerbGET, MPWRESTVerbPUT,MPWRESTVerbPOST};
    for (int i=0;i<3;i++ ) {
        PropertyPathDefs *defs = [self propertyPathDefsForVerb:verbs[i]];
        if (defs) {
            [methods addObject:[[[MPWPropertyPathMethod alloc] initWithPropertyPaths:defs->defs count:defs->count verb:defs->verb] autorelease]];
            free(defs);
        }
    }
    return methods;
}

-(NSArray*)propertyPathImplementationMethods
{
    NSMutableArray *methods=[NSMutableArray array];
    MPWRESTVerb verbs[3]={ MPWRESTVerbGET, MPWRESTVerbPUT,MPWRESTVerbPOST};
    for (int i=0;i<3;i++ ) {
        MPWRESTVerb thisVerb=verbs[i];
        NSArray *definitions=[self propertyPathDefinitionsForVerb:thisVerb];
        for (long j=0,numDefinitions=definitions.count;j<numDefinitions;j++) {
            [methods addObject:[definitions[j] methodForVerb:thisVerb]];
        }
    }
    return methods;
}

-(NSArray*)generatedMethods
{
    return [self generatedPropertyPathMethods];
}


-(NSArray*)allMethods
{
    NSArray *userDefinedMethods=self.methods;
    NSArray *generatedMethods=[self generatedMethods];
    return [userDefinedMethods arrayByAddingObjectsFromArray:generatedMethods];
}

-(NSArray*)allImplementationMethods
{
    NSArray *userDefinedMethods=self.methods;
    NSArray *propertyPathMethods=[self propertyPathImplementationMethods];
    return [userDefinedMethods arrayByAddingObjectsFromArray:propertyPathMethods];
}

-(NSArray *)allIvarNames
{
    if ( [[self instanceVariableDescriptions] count] >0 ) {
        return (NSArray *)[[[self instanceVariableDescriptions] collect] name];
    } else {
        return @[];
    }
}

-(NSString*)defaultSuperclassName
{
    return @"NSObject";
}

-(NSString*)superclassNameToUse
{
    return self.superclassName ?: [self defaultSuperclassName];
}

-(void)generateAccessors
{
    Class theClassToDefine=[self classToDefine];
    for ( NSString *ivarName in [self allIvarNames]) {
        [theClassToDefine generateAccessorsFor:ivarName];
    }
}

-(BOOL)defineJustTheClass
{
    Class superclass=NSClassFromString([self superclassNameToUse]);
    NSAssert1( NSClassFromString(self.name) == nil, @"Class '%@' should not exist when I try to defien it",self.name);
    if ( superclass ) {
        [superclass createSubclassWithName:self.name instanceVariableArray:[self instanceVariableDescriptions]];
        return YES;
    }
    return NO;
}

-(void)defineClass
{
    if ([self defineJustTheClass]) {
        [self generateAccessors];
    }
}

-(Class)classToDefine
{
    return NSClassFromString(self.name);
}

-(id)evaluateIn:(id)aContext
{
    Class theClassToDefine=[self classToDefine];
    if (!theClassToDefine) {
        [self defineClass];
    }
    [aContext defineMethodsForClassDefinition:self];
    return [self classToDefine];
}


-(void)dealloc
{
    [_superclassName release];
    [super dealloc];
}

@end
