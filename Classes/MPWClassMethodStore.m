//
//  MPWClassMethodStore.m
//  ObjectiveSmalltalk
//
//  Created by Marcel Weiher on 2/17/15.
//
//

#import "MPWClassMethodStore.h"
#import "MPWMethodCallBack.h"
#import "MPWMethod.h"
#import "MPWScriptedMethod.h"
#import "MPWMethodHeader.h"
#import "MPWClassMirror.h"

@implementation MPWClassMethodStore

objectAccessor( MPWClassMirror, classMirror, setClassMirror )
objectAccessor( NSMutableDictionary, methodCallbacks, setMethodCallbacks )
scalarAccessor( MPWStCompiler *, compiler, setCompiler)

-initWithClassMirror:(MPWClassMirror*)newMirror compiler:aCompiler
{
    self=[super init];
    [self setClassMirror:newMirror];
    [self setMethodCallbacks:[NSMutableDictionary dictionary]];
    [self setCompiler:aCompiler];
    return self;
}

-(MPWMethodCallBack*)callbackForName:(NSString*)name
{
    MPWMethodCallBack *methodCallback = [[self methodCallbacks] objectForKey:name];
    if ( methodCallback == nil ) {
        methodCallback = [[MPWMethodCallBack alloc] init];
        [[self methodCallbacks] setObject:methodCallback forKey:name];
    }
    return methodCallback;
}

-(MPWMethod*)methodForName:(NSString*)name
{
    return [[self callbackForName:name] method];
}


#ifndef __clang_analyzer__

-(MPWMethodCallBack*)addMethod:(MPWMethod*)method
{
    NSString* methodName = [[method methodHeader] methodName];
    MPWMethodCallBack *methodCallback = [self callbackForName:methodName];
    
    if (  [self compiler] ) {
        [method setContext:[self compiler]];
    }
    [methodCallback setMethod:method];
    return methodCallback;
}

#endif

-(void)installMethodNamed:(NSString*)methodName
{
    MPWMethodCallBack *methodCallback = [self callbackForName:methodName];
    [methodCallback installInClassIfNecessary:[[self classMirror] theClass]];
}

-(void)installMethod:aMethod
{
    MPWMethodCallBack *methodCallback = [self addMethod:aMethod];
    [methodCallback installInClassIfNecessary:[[self classMirror] theClass]];
}

-methodWithHeaderString:header bodyString:body
{
    id method = [[[MPWScriptedMethod alloc] init] autorelease];
    [method setContext:[self compiler]];
    [method setScript:body];
    [method setMethodHeader:[MPWMethodHeader methodHeaderWithString:header]];
    return method;
}


-(MPWMethodCallBack*)addMethodString:(NSString*)methodScript withHeaderString:(NSString*)headerString
{
    return [self addMethod:[self methodWithHeaderString:headerString bodyString:methodScript]];
}

-(void)installMethodString:(NSString*)methodScript withHeaderString:(NSString*)headerString
{
    [[self addMethodString:methodScript withHeaderString:headerString] installInClassIfNecessary:[[self classMirror] theClass]];
}

-(NSArray*)allMethodNames
{
    return [[self methodCallbacks] allKeys];
}

-(void)defineMethodsInExternalMethodDict:(NSDictionary*)dict
{
    NSArray *names=[dict allKeys];
    NSArray *bodies=[[dict collect] objectForKey:[names each]];
    [[self do] addMethodString:[bodies each] withHeaderString:[names each]];
}

-(NSDictionary*)externalMethodDict
{
    NSMutableDictionary *d=[NSMutableDictionary dictionary];
    for ( MPWMethodCallBack *callback in [[self methodCallbacks] allValues]) {
        MPWScriptedMethod *method=(MPWScriptedMethod*)[callback method];
        d[[[method methodHeader] headerString]]=[method script];
    }
    NSLog(@"external method dict for %@ -> %@",[[self classMirror] name],d);
    return d;
}

-(void)dealloc
{
    [classMirror release];
    [methodCallbacks release];
    [super dealloc];
}
@end
