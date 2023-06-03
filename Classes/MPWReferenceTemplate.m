//
//  MPWPropertyPath.m
//  ObjectiveSmalltalk
//
//  Created by Marcel Weiher on 8/6/18.
//

#import "MPWReferenceTemplate.h"
#import <MPWFoundation/MPWFoundation.h>
#import "MPWPropertyPathComponent.h"

@implementation MPWReferenceTemplate


CONVENIENCEANDINIT( propertyPath, WithReference:(id <MPWReferencing>)ref)
{
    self=[super init];
    NSMutableArray *comps=[NSMutableArray array];
    for ( NSString *s in ref.pathComponents) {
        [comps addObject:[MPWPropertyPathComponent componentWithString:s]];
    }
    self.pathComponents=comps;
    return self;
}

CONVENIENCEANDINIT( propertyPath, WithPathString:(NSString*)path)
{
    MPWGenericReference *ref=[MPWGenericReference referenceWithPath:path];

    return [self initWithReference:ref];
}

-(NSString*)name
{
    return [(NSArray*)[[self.pathComponents collect] pathName] componentsJoinedByString:@"/"];
}

-(NSDictionary*)bindingsForMatchedReference:(id <MPWReferencing>)ref
{
    NSMutableDictionary *result=[NSMutableDictionary dictionary];
    NSArray *pathComponents=[ref relativePathComponents];
    BOOL isWild=NO;
    if ( pathComponents.count > 0) {
        for (long i=0, max=MIN(pathComponents.count,self.pathComponents.count);i<max;i++) {
            NSString *segment=pathComponents[i];
            MPWPropertyPathComponent *matcher=self.pathComponents[i];
            NSString *matcherName=matcher.name;
            NSString *argName=matcher.parameter;
            
            if ( matcherName ) {
                if ( ![matcherName isEqualToString:segment]) {
                    return nil;
                }
            } else if ( argName) {
                if ( matcher.isWildcard ) {
                    isWild=YES;
                    result[argName]=[[pathComponents subarrayWithRange:NSMakeRange(i,pathComponents.count-i)] componentsJoinedByString:@"/"];
                    break;
                } else {
                    result[argName]=segment;
                }
            }
        }
    } else if ( [[ref path] isEqual:@"/"]  || [[ref path] isEqual:@""]) {
        if ( self.pathComponents.count == 1) {
            MPWPropertyPathComponent *matcher=self.pathComponents[0];
            if ( matcher.isWildcard ) {
                isWild=YES;
                result[@"/"]=@[@"/"];
           }
        }
    }

    if ( isWild || pathComponents.count == self.pathComponents.count) {
        return result;
    } else {
        return nil;
    }
}

-(NSArray*)formalParameters
{
    NSMutableArray *parameters=[NSMutableArray array];
    for ( MPWPropertyPathComponent *component in self.pathComponents) {
        if ( component.parameter ) {
            [parameters addObject:component.parameter];
        }
    }
    return parameters;
}

-(NSDictionary*)bindingsForMatchedPath:(NSString*)path
{
    return [self bindingsForMatchedReference:[MPWGenericReference referenceWithPath:path]];
}

-(NSString *)description
{
    return [NSString stringWithFormat:@"<%@:%p: pathComponents: %@>",[self class],self,[self pathComponents]];
}

-(void)dealloc
{
//    [_name release];
    [_pathComponents release];
    [super dealloc];
}


@end


@implementation MPWReferenceTemplate(testing)


+(void)testInitializeWithSingleConstantPath
{
    MPWReferenceTemplate *pp=[self propertyPathWithPathString:@"hello"];
    INTEXPECT([[pp pathComponents] count], 1, @"number of components")
    MPWPropertyPathComponent *pc=pp.pathComponents[0];
    IDEXPECT([pc name], @"hello", @"name");
    
}

+(void)testInitializeWithArguments
{
    MPWReferenceTemplate *pp=[self propertyPathWithPathString:@"hello/:arg1/world/:arg2"];
    INTEXPECT([[pp pathComponents] count], 4, @"number of components")
    IDEXPECT([pp.pathComponents[0] name], @"hello", @"name");
    IDEXPECT([pp.pathComponents[1] parameter], @"arg1", @"arg1");
    IDEXPECT([pp.pathComponents[2] name], @"world", @"name");
    IDEXPECT([pp.pathComponents[3] parameter], @"arg2", @"arg2");
    
}

+(void)testInitializeWithWildcard
{
    MPWReferenceTemplate *pp=[self propertyPathWithPathString:@"hello/*:remainder"];
    INTEXPECT([[pp pathComponents] count], 2, @"number of components")
    IDEXPECT([pp.pathComponents[0] name], @"hello", @"name");
    IDEXPECT([pp.pathComponents[1] parameter], @"remainder", @"arg1");
    EXPECTTRUE([pp.pathComponents[1] isWildcard], @"wildcard");
    
}

+(void)testMatchAgainstConstantPath
{
    MPWReferenceTemplate *pp=[self propertyPathWithPathString:@"hello/world"];
    NSDictionary *result=[pp bindingsForMatchedPath:@"hello/world"];
    EXPECTNOTNIL(result,@"got a match");
    INTEXPECT(result.count,0,@"no bound vars");
    result=[pp bindingsForMatchedPath:@"h"];
    EXPECTNIL(result,@"no match");
    
}

+(void)testMatchAgainstPathWithParameters
{
    MPWReferenceTemplate *pp=[self propertyPathWithPathString:@"hello/:arg1/world/:arg2"];
    NSDictionary *result=[pp bindingsForMatchedPath:@"hello/this/world/cruel"];
    EXPECTNOTNIL(result,@"got a match");
    INTEXPECT(result.count,2,@"two bound vars");
    IDEXPECT(result[@"arg1"],@"this",@"binding for arg1");
    IDEXPECT(result[@"arg2"],@"cruel",@"binding for arg2");
}

+(void)testNonMatchTooManyComponentsInProperty
{
    MPWReferenceTemplate *pp=[self propertyPathWithPathString:@":arg1/count"];
    NSDictionary *result=[pp bindingsForMatchedPath:@"hello"];
    EXPECTNIL(result,@"no match");
}

+(void)testMatchAgainstWildcard
{
    MPWReferenceTemplate *pp=[self propertyPathWithPathString:@"hello/:arg1/world/*:arg2"];
    NSDictionary *result=[pp bindingsForMatchedPath:@"hello/this/world/cruel/remainder"];
    EXPECTNOTNIL(result,@"got a match");
    INTEXPECT(result.count,2,@"two bound vars");
    IDEXPECT(result[@"arg2"],@"cruel/remainder",@"binding for arg2");
    
}

+(void)testMatchRootAgainstWildcard
{
    MPWReferenceTemplate *pp=[self propertyPathWithPathString:@"*"];
    NSDictionary *result=[pp bindingsForMatchedPath:@"/"];
    EXPECTNOTNIL(result,@"got a match");
    
}

+(void)testListFormalParameters
{
    MPWReferenceTemplate *pp=[self propertyPathWithPathString:@"hello/:arg1/world/:arg2"];
    NSArray *formalParameters=[pp formalParameters];
    
    INTEXPECT(formalParameters.count,2,@"two parameters");
    IDEXPECT(formalParameters,(@[ @"arg1", @"arg2"]),@"the parameters");
}


+testSelectors
{
    return @[
             @"testInitializeWithSingleConstantPath",
             @"testInitializeWithArguments",
             @"testInitializeWithWildcard",
             @"testMatchAgainstConstantPath",
             @"testMatchAgainstPathWithParameters",
             @"testMatchAgainstWildcard",
//             @"testMatchRootAgainstWildcard",
             @"testListFormalParameters",
             @"testNonMatchTooManyComponentsInProperty",
    ];
}

@end

