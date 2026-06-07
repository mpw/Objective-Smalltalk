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

@interface SailsControl()

@property (nonatomic,strong) STSiteBundle *bundle;
@property (nonatomic,assign) int port;
@property (nonatomic,assign) BOOL shouldCache;

@end

@implementation SailsControl

-(int)defaultPort
{
    return 8081;
}

-(instancetype)init
{
    self=[super init];
    self.port=[self defaultPort];
    self.shouldCache = NO;
    return self;
}

-(int)main:(int)argc argv:(const char**)argv
{
    NSMutableArray *args=[NSMutableArray array];
    for (int i=1;i<argc;i++) {
        [args addObject:@(argv[i])];
    }
    return [self main:args];
}

-(BOOL)run:(NSString*)bundlePath
{
    self.bundle = [STSiteBundle bundleWithPath:bundlePath];
    [self.bundle setShouldCache:self.shouldCache];
    [self.bundle runSimpleSite:self.port];
    [self.compiler at:@"bundle" put:self.bundle];
    [self.compiler at:@"site" put:[[self.bundle siteServer] delegate] ];
    [self.compiler evaluateScriptString:@"scheme:site ← site."];
    return YES;
}

-(void)openInBrowser
{
    NSLog(@"openInBrowser");
    NSString *open=[NSString stringWithFormat:@"open http://localhost:%d/",self.port];
    NSLog(@"%@",open);
    system([open UTF8String]);
}


-(int)main:(NSArray*)args
{
    @autoreleasepool {
        BOOL actionDone=NO;
        for (int i=0;i<args.count;i++) {
            NSString *arg = args[i];
           if ( [arg hasPrefix:@"-"]) {
                if ( [arg isEqual:@"-run"]) {
                    i++;
                    actionDone=[self run:args[i]];
                    fprintf(stderr,"run %s on port %d!\n",[[[[self.bundle siteServer] delegate] description] UTF8String],self.port);
                } else if ( [arg isEqual:@"-port"]) {
                    i++;
                    self.port=[args[i] intValue];
                } else if ( [arg isEqual:@"-open"]) {
                    i++;
                    [self openInBrowser];
                } else if ( [arg isEqual:@"-cache"]) {
                    self.shouldCache=YES;
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
                fprintf(stderr,"invalid argument: %s\n",[args[i] UTF8String]);
                help();
                break;
            }
        }
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
