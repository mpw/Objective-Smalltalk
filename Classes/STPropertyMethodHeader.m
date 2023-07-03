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
        if (verb == MPWRESTVerbPUT) {
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
        if (verb == MPWRESTVerbPUT) {
            [self addParameterName:@"newValue" type:@"id" keyWord:@"value:"];
            methodNameTemplate = @"PUT_%@:";
        } else {
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
    MPWReferenceTemplate *t=[MPWReferenceTemplate templateWithReference:@"/get/:arg1/param/:p2"];
    STPropertyMethodHeader *header=[[[self alloc] initWithTemplate:t verb:MPWRESTVerbPUT] autorelease];
    IDEXPECT( header.methodName, @"PUT_/get/:arg1/param/:p2:", @"methodName");
}

+(NSArray*)testSelectors
{
   return @[
			@"testMethodName",
			];
}

@end
