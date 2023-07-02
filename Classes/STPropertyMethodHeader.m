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
            self.returnType = [STTypeDescriptor descritptorForObjcCode:'v'];
        } else {
            self.returnType = [STTypeDescriptor descritptorForObjcCode:'@'];
        }
        self.template = newTemplate;
        NSString *keyword=@"methodArg:";
        for ( NSString *parameterName in newTemplate.formalParameters) {
            [self addParameterName:parameterName type:@"id" keyWord:keyword];
            keyword=@"Arg:";
        }
        [self addParameterName:@"theRef" type:@"id" keyWord:@"ref:"];
        if (verb == MPWRESTVerbPUT) {
            [self addParameterName:@"newValue" type:@"id" keyWord:@"value:"];
        }
    }
    return self;
}

@end


#import <MPWFoundation/DebugMacros.h>

@implementation STPropertyMethodHeader(testing) 

+(void)someTest
{
	EXPECTTRUE(false, @"implemented");
}

+(NSArray*)testSelectors
{
   return @[
//			@"someTest",
			];
}

@end
