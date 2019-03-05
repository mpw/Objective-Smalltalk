//
//  MPWPropertyPathComponent.m
//  ObjectiveSmalltalk
//
//  Created by Marcel Weiher on 8/6/18.
//

#import "MPWPropertyPathComponent.h"
#import <MPWFoundation/MPWFoundation.h>

@implementation MPWPropertyPathComponent

CONVENIENCEANDINIT( component, WithString:(NSString*)s)
{
    self=[super init];
    if ( [s hasPrefix:@"*:"]) {
        self.isWildcard=YES;
        self.parameter=[s substringFromIndex:2];
    } else if ( [s hasPrefix:@":"]) {
        self.parameter=[s substringFromIndex:1];
    } else {
        self.name=s;
    }
    return self;
}

-(NSString*)pathName
{
    NSMutableString *pathName=[NSMutableString string];
    if ( [self isWildcard]) {
        [pathName appendString:@"*"];
    }
    if ( [self parameter]) {
        [pathName appendString:@":"];
        [pathName appendString:self.parameter];
    } else  if ( self.name) {
        [pathName appendString:self.name];
    }
    return pathName;
}

-(NSString *)description
{
    return [NSString stringWithFormat:@"<%@:%p: propertyPath: name: %@ paramater: %@>",[self class],self,self.name,self.parameter];
}

-(void)dealloc
{
    [_name release];
    [_parameter release];
    [super dealloc];    
}

@end


@implementation MPWPropertyPathComponent(testing)

+(void)testPathComponentFromNameSpec
{
    MPWPropertyPathComponent *comp=[self componentWithString:@"pathName"];
    EXPECTFALSE( [comp isWildcard], @"wildcard");
    IDEXPECT( [comp name], @"pathName",@"name");
    EXPECTNIL( [comp parameter],@"parameter");
}

+(void)testPathComponentFromParameterSpec
{
    MPWPropertyPathComponent *comp=[self componentWithString:@":parameter"];
    EXPECTFALSE( [comp isWildcard], @"wildcard");
    IDEXPECT( [comp parameter], @"parameter",@"parameterName");
    EXPECTNIL( [comp name],@"name");
}

+(void)testPathComponentFromWildcardSpec
{
    MPWPropertyPathComponent *comp=[self componentWithString:@"*:wildparam"];
    EXPECTTRUE( [comp isWildcard], @"wildcard");
    IDEXPECT( [comp parameter], @"wildparam",@"parameterName");
    EXPECTNIL( [comp name],@"name");
}

+testSelectors
{
    return @[
             @"testPathComponentFromNameSpec",
             @"testPathComponentFromParameterSpec",
             @"testPathComponentFromWildcardSpec",
             ];
}

@end

