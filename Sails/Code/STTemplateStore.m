//
//  STTemplateStore.m
//  Sails
//
//  Created by Marcel Weiher on 05.03.24.
//

#import "STTemplateStore.h"
#import "STSiteBundle.h"
#import "STEntityList.h"

@interface STTemplateStore()

@property (nonatomic, strong) id <MPWStorage> templateNames;
@property (nonatomic, strong) NSString *templateName;
@property (nonatomic, strong) STSiteBundle *bundle;


@end

@implementation STTemplateStore

-(void)setSource:(NSObject<MPWStorage,MPWHierarchicalStorage,StreamStorage> *)newSource
{
    [super setSource:newSource];
    if ( [newSource respondsToSelector:@selector(templateNameMapper)] ) {
        self.templateNames = [newSource templateNameMapper];
    }
}


-(MPWStringTemplate*)applyContext:aContext toTemplateNamed:templateName {
    NSString *templateString = [[self.bundle.resources at:templateName]  stringValue];
    return [templateString evaluateAsTemplateWith: aContext];
}

-(NSString*)templateNameForRef:ref
{
    if ( self.templateNames ) {
        return [self.templateNames at:ref];
    } else {
        return self.templateName;
    }
}

-mapRetrievedObject:anObject forReference:ref {
    MPWStringTemplate *template = [self templateNameForRef:ref];
    if (![anObject isKindOfClass: [MPWReference class]] ) {
        anObject = [self applyContext: anObject  toTemplateNamed:template];
    } else {
//        NSLog(@"got a binding: %@",anObject);
    }
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
