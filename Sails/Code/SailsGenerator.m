//
//  SailsGenerator.m
//  Sails
//
//  Created by Marcel Weiher on 01.01.24.
//

#import "SailsGenerator.h"
#import <ObjectiveSmalltalk/ObjectiveSmalltalk.h>
#import <ObjectiveSmalltalk/MPWInstanceVariable.h>
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

-(NSString*)makeEntityNamed:(NSString*)entityName superclassName:(NSString*)superclassName ivarNames:(NSArray*)ivarnames
{
    STClassDefinition *def=[[STClassDefinition new] autorelease];
    def.name = entityName;
    def.superclassName = superclassName ?: @"STEntity";
    NSMutableArray *ivarDefs=[NSMutableArray array];
    for ( NSString *name in ivarnames ) {
        MPWInstanceVariable *vardef=[[MPWInstanceVariable new] autorelease];
        vardef.name = name;
        [ivarDefs addObject:vardef];
    }
    def.instanceVariableDescriptions=ivarDefs;
    MPWStringTemplate *template=[MPWStringTemplate templateWithString:[[self frameworkResource:@"Entity" category:@"st"] stringValue]];
    NSString *result = [template evaluateWith:def];
    return result;
}

-(void)makeSiteOfType:(NSString*)siteType
{
    if ( [siteType isEqual:@"dynamic"]) {
        [self makeDynamic];
    } else {
        [self makeStatic];
    }
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

+(void)testCreateSimpleEntity
{
    SailsGenerator *generator = [[self new] autorelease];
    NSString *expected = @"Post:STEntity {\n   var first. var last. \n}\n";
    NSString *generated = [generator makeEntityNamed:@"Post" superclassName:nil ivarNames:@[  @"first", @"last" ] ];
    IDEXPECT(generated,expected, @"class for entity 'Post' with ivars 'first' and 'last'");
}

+(NSArray*)testSelectors
{
   return @[
       @"testBasicGeneration",
       @"testCreateSimpleEntity",
			];
}

@end
