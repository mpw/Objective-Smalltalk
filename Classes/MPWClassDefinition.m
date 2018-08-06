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

@implementation MPWClassDefinition


-(void)addMethodsIn:(MPWClassMethodStore*)store
{
    for ( MPWScriptedMethod *method in self.methods) {
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
