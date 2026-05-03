//
//  SailsControl.m
//  Sails
//
//  Created by Marcel Weiher on 03.05.26.
//

#import "SailsControl.h"
#import "STSiteBundle.h"
#import <MPWFoundation/MPWFoundation.h>
#import <Sails/SailsGenerator.h>


void help(void )
{
    fprintf(stderr,"-run <bundle>, -generate, -port <n>\n");
}

@implementation SailsControl

-(int)main:(int)argc argv:(const char**)argv stsh:stsh
{
    NSMutableArray *args=[NSMutableArray array];
    for (int i=1;i<=argc;i++) {
        [args addObject:@(argv[0])];
    }
    return [self main:args stsh:stsh];
}

-(int)main:(NSArray*)args stsh:stsh
{
    @autoreleasepool {
        BOOL actionDone=NO;
        STSiteBundle* bundle=nil;
        int port=8081;
        for (int i=0;i<args.count;i++) {
            NSString *arg = args[i];
            if ( [arg hasPrefix:@"-"]) {
                if ( [arg isEqual:@"-run"]) {
                    i++;
                    NSString *path = args[i];
                    bundle = [STSiteBundle bundleWithPath:path];
                    [bundle runSimpleSite:port];
                    [[stsh evaluator] bindValue:bundle toVariableNamed:@"bundle"];
                    [[stsh evaluator] bindValue:[[bundle siteServer] delegate] toVariableNamed:@"site"];
                    [[stsh evaluator] evaluateScriptString:@"scheme:site ← site."];
                    actionDone=YES;
                    break;
                } else if ( [arg isEqual:@"-port"]) {
                    i++;
                    port=[args[i] intValue];;
                } else if ( [arg isEqual:@"-generate"]) {
                    i++;
                    NSString *type=@"-static";
                    NSString *path = args[i];
                    if ( [path hasPrefix:@"-"]) {
                        i++;
                        type=[path substringFromIndex:1];
                        path = args[i];
                    }
                    SailsGenerator *generator = [[SailsGenerator new] autorelease];
                    generator.path = path;
                    [generator makeSiteOfType:type];
                    [generator generate];
                    actionDone=YES;
                    return 0;
                }
            } else {
                fprintf(stderr,"invalid argument: %@\n",args[i]);
                help();
                break;
            }
        }
        if (!actionDone) {
            fprintf(stderr,"no action specified!\n");
            help();
            return 1;
        }
        fprintf(stderr,"run %s on port %d!\n",[[[[bundle siteServer] delegate] description] UTF8String],port);
    }
    return 0;      // ...and make main fit the ANSI spec.
}

@end


#import <MPWFoundation/DebugMacros.h>

@implementation SailsControl(testing) 

+(void)someTest
{
//	EXPECTTRUE(false, @"implemented");
}

+(NSArray*)testSelectors
{
   return @[
//			@"someTest",
			];
}

@end
