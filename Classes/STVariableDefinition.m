//
//  STVariableDefinition.m
//  ObjectiveSmalltalk
//
//  Created by Marcel Weiher on 01.07.21.
//

#import "STVariableDefinition.h"

@interface STVariableDefinition ()

@property (nonatomic, strong ) MPWVariableDefinition *definition;

@end

@implementation STVariableDefinition

-initWithName:(NSString*)newName type:(STTypeDescriptor*)newType
{
    self=[super init];
    self.definition = [[[MPWVariableDefinition alloc] initWithName:newName type:newType] autorelease];
    return self;
}

-(NSString*)name {
    return self.definition.name;
}

-(NSString*)type {
    return self.definition.type;
}

-(id)evaluateIn:(id)aContext
{
    [aContext declareVariable:self.name];
    if ( self.initializer) {
        [aContext bindValue:[self.initializer evaluateIn:aContext] toVariableNamed:self.name];
    }
}

-(void)accumulateLocalVars:(NSMutableArray*)vars
{
    [vars addObject:self.name];
}

-(void)dealloc
{
    [_definition release];
    [_initializer release];
    [super dealloc];
}

@end


#import <MPWFoundation/DebugMacros.h>

@implementation STVariableDefinition(testing) 

+(void)someTest
{
//	EXPECTTRUE(false, @"implemented");
}

+(NSArray*)testSelectors
{
   return @[
//			@"someTest",
			];
}

@end
