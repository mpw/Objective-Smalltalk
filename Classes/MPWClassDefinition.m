//
//  MPWClassDefinition.m
//  ObjectiveSmalltalk
//
//  Created by Marcel Weiher on 4/12/17.
//
//

#import "MPWClassDefinition.h"
#import "NSObjectScripting.h"
#import "MPWClassMethodStore.h"

@implementation MPWClassDefinition


-(void)addMethodsIn:(MPWClassMethodStore*)store
{
    for ( MPWMethod *method in self.methods) {
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

-(id)evaluateIn:(id)aContext
{
    Class theClassToDefine=NSClassFromString(self.name);
    if (!theClassToDefine) {
        Class superclass;
        if (self.superclassName) {
            superclass=NSClassFromString(self.superclassName);
        } else {
            superclass=[NSObject class];  // FIXME should probably be pluggable
        }
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
    [super dealloc];
}

@end
