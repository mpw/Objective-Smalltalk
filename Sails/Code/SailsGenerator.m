//
//  SailsGenerator.m
//  Sails
//
//  Created by Marcel Weiher on 01.01.24.
//

#import "SailsGenerator.h"
#import <ObjectiveSmalltalk/ObjectiveSmalltalk.h>
#import "STSiteBundle.h"



@implementation SailsGenerator
{
    STSiteBundle *bundle;
}

lazyAccessor(STSiteBundle*, bundle, setBundle, createBundle )

-(STSiteBundle*)createBundle
{
    return [STSiteBundle bundleWithPath:self.path];
}


-(void)setClass:(NSString*)className
{
    self.bundle.info = @{ @"site": className};
}



-(void)createSimpleDynamic
{
    [self setClass:@"DynamicSite"];
    self.bundle.cachedSources[@"DynamicSite.st"]=[self frameworkResource:@"DynamicSite" category:@"st"];
    self.bundle.cachedResources[@"index.html"]=[self frameworkResource:@"index" category:@"html"];

}

-(BOOL)generate
{
    [self createSimpleDynamic];
    self.bundle.saveSource=YES;
    [self.bundle methodDict];
    [self.bundle save];
    return YES;
}

@end


#import <MPWFoundation/DebugMacros.h>

@implementation SailsGenerator(testing) 

+(void)testBasicGeneration
{
    NSString *path=@"/tmp/generatortest.sited";
    SailsGenerator *generator = [[self new] autorelease];
    generator.path = path;
    EXPECTTRUE([generator generate],@"generation succeeded");
}

+(NSArray*)testSelectors
{
   return @[
			@"testBasicGeneration",
			];
}

@end
