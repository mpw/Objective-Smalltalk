//
//  STTemplateStore.m
//  Sails
//
//  Created by Marcel Weiher on 05.03.24.
//

#import "STTemplateStore.h"
#import "STSiteBundle.h"

@interface STTemplateStore()

@property (nonatomic, strong) id <MPWStorage> templateNames;
@property (nonatomic, strong) STSiteBundle *bundle;


@end

@implementation STTemplateStore


-(MPWStringTemplate*)applyContext:aContext toTemplateNamed:templateName {
    NSString *templateString = [[self.bundle.resources at:templateName]  stringValue];
    return [templateString evaluateAsTemplateWith: aContext];
}

-mapRetrievedObject:anObject forReference:ref {
    MPWStringTemplate *template = [self.templateNames at:ref];
    if (![anObject isKindOfClass: [MPWBinding class]] ) {
        anObject = [self applyContext: anObject  toTemplateNamed:template];
    };
    return anObject;
}

@end


#import <MPWFoundation/DebugMacros.h>

@implementation STTemplateStore(testing) 

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
