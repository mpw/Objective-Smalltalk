//
//  MPWClassDefinition.m
//  ObjectiveSmalltalk
//
//  Created by Marcel Weiher on 4/12/17.
//
//

#import "MPWClassDefinition.h"
#import "NSObjectScripting.h"
#import "MPWMethodStore.h"
#import "MPWClassMethodStore.h"
#import "STCompiler.h"
#import "MPWPropertyPathMethod.h"
#import "MPWPropertyPathDefinition.h"


@implementation MPWClassDefinition


-(NSArray*)propertyPathDefinitionsForVerb:(MPWRESTVerb)verb
{
    NSMutableArray *ppdefs=[NSMutableArray array];
    for ( MPWPropertyPathDefinition *def in self.propertyPathDefinitions) {
        if ( [def methodForVerb:verb] ) {
            [ppdefs addObject:def];
        }
    }
    return ppdefs;
}

-(NSArray*)generatedPropertyPathMethods
{
    NSMutableArray *methods=[NSMutableArray array];
    MPWRESTVerb verbs[2]={ MPWRESTVerbGET, MPWRESTVerbPUT};
    for (int i=0;i<2;i++ ) {
        MPWRESTVerb thisVerb=verbs[i];
        NSArray *definitions=[self propertyPathDefinitionsForVerb:thisVerb];
        long numDefinitions=definitions.count;
        if ( numDefinitions ) {
            PropertyPathDefs *defs=calloc( sizeof(PropertyPathDefs)+numDefinitions*sizeof(PropertyPathDef),1);
            defs->verb = thisVerb;
            defs->count = (int)numDefinitions;
            for (long j=0;j<numDefinitions;j++) {
                defs->defs[j].function=NULL;
                defs->defs[j].method = [definitions[j] methodForVerb:thisVerb];
                defs->defs[j].propertyPath = (id)[definitions[j] propertyPath];
            }
            [methods addObject:[[[MPWPropertyPathMethod alloc] initWithPropertyPaths:defs] autorelease]];
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

-(void)defineClass
{
    Class superclass=NSClassFromString([self superclassNameToUse]);
    if ( superclass ) {
        [superclass createSubclassWithName:self.name instanceVariableArray:[self instanceVariableDescriptions]];
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
