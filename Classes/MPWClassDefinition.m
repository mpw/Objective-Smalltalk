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
#import "MPWStCompiler.h"
#import "MPWPropertyPathGetter.h"
#import "MPWPropertyPathSetter.h"



@implementation MPWClassDefinition

-(NSArray*)generatedMethods
{
    NSMutableArray *methods=[NSMutableArray array];
    
    if ( self.propertyPathDefinitions.count) {
        [methods addObject:[MPWPropertyPathGetter getterWithPropertyPathDefinitions:self.propertyPathDefinitions]];
        [methods addObject:[MPWPropertyPathSetter getterWithPropertyPathDefinitions:self.propertyPathDefinitions]];
    }
    return methods;
}


-(NSArray*)allMethods
{
    NSArray *userDefinedMethods=self.methods;
    NSArray *generatedMethods=[self generatedMethods];
    return [userDefinedMethods arrayByAddingObjectsFromArray:generatedMethods];
}

-(void)addMethodsIn:(MPWClassMethodStore*)store
{
    for ( MPWScriptedMethod *method in [self allMethods]) {
        [store installMethod:method];
    }
}

-(NSArray *)ivarNames
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

-(id)evaluateIn:(id)aContext
{
    Class theClassToDefine=NSClassFromString(self.name);
    if (!theClassToDefine) {
        Class superclass=NSClassFromString([self superclassNameToUse]);
        if ( superclass ) {
            [superclass createSubclassWithName:self.name instanceVariableArray:[self ivarNames]];
            theClassToDefine=NSClassFromString(self.name);
            for ( NSString *ivarName in [self ivarNames]) {
                   [theClassToDefine generateAccessorsFor:ivarName];

            }
        }
    }
    [self addMethodsIn:[aContext classStoreForName:self.name]];
    return theClassToDefine;
}


-(void)dealloc
{
    [_name release];
    [_superclassName release];
    [_instanceVariableDescriptions release];
    [_methods release];
    [_propertyPathDefinitions release];
    [super dealloc];
}

@end
