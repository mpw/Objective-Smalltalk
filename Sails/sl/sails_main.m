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

int main (int argc, const char *argv[])
{
    @autoreleasepool {
        STSiteBundle* bundle=nil;
        int port=8081;
        NSMutableArray *args=[NSMutableArray array];
        STShell *stsh=[[[STShell alloc] initWithArgs:args] autorelease];
        [stsh setCommandName:[NSString stringWithUTF8String:argv[0]]];
        NSLog(@"argc: %d",argc);
        for (int i=1;i<=argc;i++) {
            NSString *arg = [NSString stringWithUTF8String:argv[i]];
            if ( [arg hasPrefix:@"-"]) {
                if ( [arg isEqual:@"-run"]) {
                    i++;
                    NSString *path = [NSString stringWithUTF8String:argv[i]];
                    bundle = [STSiteBundle bundleWithPath:path];
                    [bundle runSite:port];
                    [[stsh evaluator] bindValue:bundle toVariableNamed:@"site"];
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
                        type=path;
                        path = [NSString stringWithUTF8String:argv[i]];
                    }
                    NSLog(@"type: %@",type);
                    SailsGenerator *generator = [[SailsGenerator new] autorelease];
                    generator.path = path;
                    if ( [type isEqual:@"-dynamic"] ) {
                        [generator makeDynamic];
                    } else {
                        [generator makeStatic];
                    }
                    [generator generate];
                    return 0;
                }
            } else {
                break;
            }

            
        }
        [stsh run];
        exit(0);       // insure the process exit status is 0
    }
    return 0;      // ...and make main fit the ANSI spec.
}
