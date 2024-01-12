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

-(void)copySources:(NSString*)name
{
    self.bundle.cachedSources[name]=[self frameworkResource:name category:@""];
}

-(void)copyResources:(NSString*)name
{
    self.bundle.cachedResources[name]=[self frameworkResource:name category:@""];
}

-(void)makeStatic
{
    [self setClass:@"StaticSite"];
    [self copySources:@"StaticSite.st"];
    [self copyResources:@"index.html"];
    
}
-(void)makeDynamic
{
    [self setClass:@"DynamicSite"];
    [self copySources:@"DynamicSite.st"];
}

-(BOOL)generate
{
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
    [generator makeStatic];
    EXPECTTRUE([generator generate],@"generation succeeded");
}

+(NSArray*)testSelectors
{
   return @[
			@"testBasicGeneration",
			];
}

@end
