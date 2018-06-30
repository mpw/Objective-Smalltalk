//
//  MPWClassMethodStore.h
//  ObjectiveSmalltalk
//
//  Created by Marcel Weiher on 2/17/15.
//
//

#import <MPWFoundation/MPWFoundation.h>

@class MPWClassMirror,MPWStCompiler,MPWMethodCallBack,MPWScriptedMethod;

@interface MPWClassMethodStore : NSObject
{
    MPWClassMirror  *classMirror;
    NSMutableDictionary *methodCallbacks;
    MPWStCompiler   *compiler;
}

-initWithClassMirror:(MPWClassMirror*)newMirror compiler:aCompiler;
-(MPWMethodCallBack*)addMethod:(MPWScriptedMethod*)method;
-(void)installMethod:(MPWScriptedMethod*)method;
-(MPWScriptedMethod*)methodForName:(NSString*)name;
-(NSArray*)allMethodNames;
-(void)defineMethodsInExternalMethodDict:(NSDictionary*)dict;
-(NSDictionary*)externalMethodDict;
-(MPWMethodCallBack*)addMethodString:(NSString*)methodScript withHeaderString:(NSString*)headerString;
-(void)installMethodString:(NSString*)methodScript withHeaderString:(NSString*)headerString;

@end
