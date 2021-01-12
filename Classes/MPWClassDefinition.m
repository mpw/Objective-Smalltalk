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

-(void)addMethodsInStore:(MPWClassMethodStore*)store
{
    for ( MPWScriptedMethod *method in [self allMethods]) {
        [store installMethod:method];
    }
    if ( self.classMethods.count) {
        for ( MPWScriptedMethod *method in [self classMethods]) {
            [store installClassMethod:method];
        }
    }
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
        [superclass createSubclassWithName:self.name instanceVariableArray:[self allIvarNames]];
        [self generateAccessors];
    }
}

-(Class)classToDefine
{
    return NSClassFromString(self.name);
}

-(void)defineMethodsInContext:aContext
{
    [self addMethodsInStore:[aContext classStoreForName:self.name]];
}

-(id)evaluateIn:(id)aContext
{
    Class theClassToDefine=[self classToDefine];
    if (!theClassToDefine) {
        [self defineClass];
    }
    [self defineMethodsInContext:aContext];
    return [self classToDefine];
}


-(void)dealloc
{
    [_superclassName release];
    [super dealloc];
}

@end
