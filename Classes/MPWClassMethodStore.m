//
//  MPWClassMethodStore.m
//  ObjectiveSmalltalk
//
//  Created by Marcel Weiher on 2/17/15.
//
//

#import "MPWClassMethodStore.h"
#import "MPWMethodCallBack.h"
//#import "MPWAbstractInterpretedMethod.h"
#import "MPWScriptedMethod.h"
#import "MPWMethodHeader.h"
#import "MPWClassMirror.h"

@implementation MPWClassMethodStore

objectAccessor(MPWClassMirror*, classMirror, setClassMirror )
objectAccessor(NSMutableDictionary*, methodCallbacks, setMethodCallbacks )
scalarAccessor( STCompiler *, compiler, setCompiler)

-(Class)theClass
{
    return [[self classMirror] theClass];
}

-(Class)theMetaClass
{
    return [[[self classMirror] metaClassMirror] theClass];
}

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
//        NSLog(@"allocating callback in callbackForName: '%@'",name);
        methodCallback = [[MPWMethodCallBack alloc] init];
        [[self methodCallbacks] setObject:methodCallback forKey:name];
    }
    return methodCallback;
}

-(MPWScriptedMethod*)methodForName:(NSString*)name
{
    return (MPWScriptedMethod*)[[self callbackForName:name] method];
}


#ifndef __clang_analyzer__

-(MPWMethodCallBack*)addMethod:(MPWScriptedMethod*)method
{
    NSString* methodName = [[method methodHeader] methodName];
    MPWMethodCallBack *methodCallback = [self callbackForName:methodName];
    method.classOfMethod = classMirror.theClass;
    [methodCallback setMethod:method];
//    NSLog(@"addMethod class %@ methodName: %@ callback: %@ method %@",[[self classMirror] name],methodName,methodCallback,method);
    if (  [self compiler] ) {
        [method setContext:[self compiler]];
    }
    return methodCallback;
}

-(MPWMethodCallBack*)addClassMethod:(MPWScriptedMethod*)method
{
    NSString* methodName = [[method methodHeader] methodName];
    MPWMethodCallBack *methodCallback = [self callbackForName:methodName];
    [methodCallback setMethod:method];
//    NSLog(@"addMethod class %@ methodName: %@ callback: %@ method %@",[[self classMirror] name],methodName,methodCallback,method);
    if (  [self compiler] ) {
        [method setContext:[self compiler]];
    }
    return methodCallback;
}



#endif

-(void)installMethodNamed:(NSString*)methodName
{
    MPWMethodCallBack *methodCallback = [self callbackForName:methodName];
    [methodCallback installInClassIfNecessary:[self theClass]];
}

-(void)installMethod:aMethod
{
    MPWMethodCallBack *methodCallback = [self addMethod:aMethod];
    [methodCallback installInClassIfNecessary:[self theClass]];
}

-(void)installClassMethod:aMethod
{
    MPWMethodCallBack *methodCallback = [self addClassMethod:aMethod];
    [methodCallback installInClassIfNecessary:[self theMetaClass]];
}

-methodWithHeaderString:header bodyString:body
{
    MPWScriptedMethod* method = [[[MPWScriptedMethod alloc] init] autorelease];
    [method setContext:[self compiler]];
    [method setScript:body];
    [method setMethodHeader:[MPWMethodHeader methodHeaderWithString:header]];
    method.classOfMethod = classMirror.theClass;
    return method;
}


-(MPWMethodCallBack*)addMethodString:(NSString*)methodScript withHeaderString:(NSString*)headerString
{
    return [self addMethod:[self methodWithHeaderString:headerString bodyString:methodScript]];
}

-(void)installMethodString:(NSString*)methodScript withHeaderString:(NSString*)headerString
{
    [[self addMethodString:methodScript withHeaderString:headerString] installInClassIfNecessary:[self theClass]];
}

-(void)installMethods
{
    [[[[self methodCallbacks] allValues] do] installInClassIfNecessary:[self theClass]];
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
    for ( NSString *methodName in [self allMethodNames] ) {
//        NSLog(@"class %@ methodName %@",[[self classMirror] name],methodName);
        MPWMethodCallBack *callback=[self methodCallbacks][methodName];
        MPWScriptedMethod *method=(MPWScriptedMethod*)[callback method];
        NSString *headerString=[[method methodHeader] headerString];
        if ( headerString ) {
            d[headerString]=[method script];
        } else {
            NSLog(@"class %@ methodName: %@ callback: %@ method: %@ no method header string",[[self classMirror] name],methodName,callback,method);
        }
    }
//    NSLog(@"external method dict for %@ -> %@",[[self classMirror] name],d);
    return d;
}

-(void)dealloc
{
    [classMirror release];
    [methodCallbacks release];
    [super dealloc];
}
@end
