//
//  MPWClassMethodStore.h
//  ObjectiveSmalltalk
//
//  Created by Marcel Weiher on 2/17/15.
//
//

#import <MPWFoundation/MPWFoundation.h>

@class MPWClassMirror,STCompiler,MPWMethodCallBack,STScriptedMethod;

@interface MPWClassMethodStore : NSObject
{
    MPWClassMirror  *classMirror;
    NSMutableDictionary *methodCallbacks;
    STCompiler   *compiler;
}

-initWithClassMirror:(MPWClassMirror*)newMirror compiler:aCompiler;
-(MPWMethodCallBack*)addMethod:(STScriptedMethod*)method;
-(void)installMethod:(STScriptedMethod*)method;
-(STScriptedMethod*)methodForName:(NSString*)name;
-(NSArray*)allMethodNames;
-(void)defineMethodsInExternalMethodDict:(NSDictionary*)dict;
-(NSDictionary*)externalMethodDict;
-(MPWMethodCallBack*)addMethodString:(NSString*)methodScript withHeaderString:(NSString*)headerString;
-(void)installMethodString:(NSString*)methodScript withHeaderString:(NSString*)headerString;
-(void)installClassMethod:aMethod;

@end
