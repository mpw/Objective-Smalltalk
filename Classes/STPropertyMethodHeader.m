//
//  STPropertyMethodHeader.m
//  ObjectiveSmalltalk
//
//  Created by Marcel Weiher on 02.07.23.
//

#import "STPropertyMethodHeader.h"
#import "STTypeDescriptor.h"

@interface STPropertyMethodHeader()

@property (nonatomic,strong ) MPWReferenceTemplate *template;

@end

@implementation STPropertyMethodHeader
{
    MPWRESTVerb verb;
}

-(instancetype)initWithTemplate:(MPWReferenceTemplate*)newTemplate verb:(MPWRESTVerb)newVerb
{
    if ( self = [super init]) {
        verb=newVerb;
        if (verb == MPWRESTVerbPUT || verb == MPWRESTVerbPOST) {
            self.returnType = [STTypeDescriptor voidType];
        } else {
            self.returnType = [STTypeDescriptor idType];
        }
        self.template = newTemplate;
        for ( NSString *parameterName in newTemplate.formalParameters) {
            [self addParameterName:parameterName type:@"id" keyWord:parameterName];
        }
        [self addParameterName:@"theRef" type:@"id" keyWord:@"ref:"];
        NSString *methodNameTemplate=nil;
        if (verb == MPWRESTVerbPUT ) {
            [self addParameterName:@"newValue" type:@"id" keyWord:@"value:"];
            methodNameTemplate = @"PUT_%@:";
        } else if (verb == MPWRESTVerbPOST ) {
            [self addParameterName:@"newValue" type:@"id" keyWord:@"value:"];
            methodNameTemplate = @"POST_%@:";
        } else  {
            methodNameTemplate = @"GET_%@";
        }
        [self setMethodName:[NSString stringWithFormat:methodNameTemplate,[newTemplate name]]];
    }
    return self;
}

@end


#import <MPWFoundation/DebugMacros.h>

@implementation STPropertyMethodHeader(testing) 

+(void)testMethodName
{
    MPWReferenceTemplate *t=[MPWReferenceTemplate templateWithReference:@"/property/:arg1/param/:p2"];
    STPropertyMethodHeader *header_put=[[[self alloc] initWithTemplate:t verb:MPWRESTVerbPUT] autorelease];
    IDEXPECT( header_put.methodName, @"PUT_/property/:arg1/param/:p2:", @"methodName");
    STPropertyMethodHeader *header_get=[[[self alloc] initWithTemplate:t verb:MPWRESTVerbGET] autorelease];
    IDEXPECT( header_get.methodName, @"GET_/property/:arg1/param/:p2", @"methodName");
}

+(void)testArgsAndReturnType
{
    MPWReferenceTemplate *t=[MPWReferenceTemplate templateWithReference:@"/property/:arg1/param/:p2"];
    STPropertyMethodHeader *header_put=[[[self alloc] initWithTemplate:t verb:MPWRESTVerbPUT] autorelease];
    IDEXPECT( @([header_put typeSignature]),@"v@:@@@@", @"method signature for PUT with 2 path matches")
    STPropertyMethodHeader *header_get=[[[self alloc] initWithTemplate:t verb:MPWRESTVerbGET] autorelease];
    IDEXPECT( @([header_get typeSignature]), @"@@:@@@", @"method signature for GET with 2 path matches");
}

+(NSArray*)testSelectors
{
   return @[
       @"testMethodName",
       @"testArgsAndReturnType",
			];
}

@end
