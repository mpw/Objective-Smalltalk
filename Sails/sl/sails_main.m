//
//  main.m
//  stsh
//
//  Created by Marcel Weiher on 12/1/13.
//
//


#import <MPWFoundation/MPWFoundation.h>
#import "STShell.h"
#import <Sails/Sails.h>

void help(void )
{
    fprintf(stderr,"-run <bundle>, -generate, -port <n>\n");
}

int main (int argc, const char *argv[])
{
    @autoreleasepool {
        BOOL actionDone=NO;
        STSiteBundle* bundle=nil;
        int port=8081;
        NSMutableArray *args=[NSMutableArray array];
        STShell *stsh=[[[STShell alloc] initWithArgs:args] autorelease];
        [stsh setCommandName:[NSString stringWithUTF8String:argv[0]]];
        for (int i=1;i<argc;i++) {
            NSString *arg = [NSString stringWithUTF8String:argv[i]];
            if ( [arg hasPrefix:@"-"]) {
                if ( [arg isEqual:@"-run"]) {
                    i++;
                    NSString *path = [NSString stringWithUTF8String:argv[i]];
                    bundle = [STSiteBundle bundleWithPath:path];
                    [bundle runSimpleSite:port];
                    [[stsh evaluator] bindValue:bundle toVariableNamed:@"bundle"];
                    [[stsh evaluator] bindValue:[[bundle siteServer] delegate] toVariableNamed:@"site"];
                    [[stsh evaluator] evaluateScriptString:@"scheme:site ← site."];
                    actionDone=YES;
                    break;
                } else if ( [arg isEqual:@"-port"]) {
                    i++;
                    port=atoi(argv[i]);
                } else if ( [arg isEqual:@"-generate"]) {
                    i++;
                    NSString *type=@"-static";
                    NSString *path = [NSString stringWithUTF8String:argv[i]];
                    if ( [path hasPrefix:@"-"]) {
                        i++;
                        type=[path substringFromIndex:1];
                        path = [NSString stringWithUTF8String:argv[i]];
                    }
                    SailsGenerator *generator = [[SailsGenerator new] autorelease];
                    generator.path = path;
                    [generator makeSiteOfType:type];
                    [generator generate];
                    actionDone=YES;
                    return 0;
                }
            } else {
                fprintf(stderr,"invalid argument: %s\n",argv[i]);
                help();
                break;
            }
        }
        if (!actionDone) {
            fprintf(stderr,"no action specified!\n");
            help();
            exit(1);
        }
        fprintf(stderr,"run %s on port %d!\n",[[[[bundle siteServer] delegate] description] UTF8String],port);
        [stsh run];
        exit(0);       // insure the process exit status is 0
    }
    return 0;      // ...and make main fit the ANSI spec.
}

