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

-(BOOL)generate
{
    STSiteBundle *site=[STSiteBundle bundleWithPath:self.path];
    [site save];
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
