//
//  MPWAppDelegate.m
//  ObjectiveSmalltalkUI
//
//  Created by Marcel Weiher on 31.03.19.
//

#import "MPWAppDelegate.h"
#import "STCompiler.h"

@implementation MPWAppDelegate

-(void)loadSmalltalkMethodsFromDirectory:(NSString*)appBundleSubDir
{
    NSBundle *appBundle = [NSBundle bundleForClass:[self class]];
    NSString *smalltalkDirectory = [[appBundle resourcePath] stringByAppendingPathComponent:appBundleSubDir];
    NSFileManager *fm=[NSFileManager defaultManager];
    for ( NSString *stFile in [[fm contentsOfDirectoryAtPath:smalltalkDirectory error:nil] sortedArrayUsingSelector:@selector(compare:)] ) {
        NSError *error=nil;
        NSString *smalltalk=[NSString stringWithContentsOfFile:[smalltalkDirectory stringByAppendingPathComponent:stFile] encoding:NSUTF8StringEncoding error:&error];
        if ( smalltalk ) {
            @try {
                [self.compiler evaluateScriptString:smalltalk];
            } @catch ( id stException ) {
                NSLog(@"error evaluating %@: %@",stFile,stException);
            }
        } else {
            NSLog(@"error opening %@: %@",stFile,error);
        }
    }
}
-(void)loadSmalltalkMethods
{
    [self loadSmalltalkMethodsFromDirectory:@"smalltalk"];
}

-(instancetype)init
{
    self=[super init];
    self.compiler = [STCompiler compiler];
    [self.compiler bindValue:self toVariableNamed:@"delegate"];
    [self.compiler bindValue:self.compiler toVariableNamed:@"smalltalk"];
    [self.compiler evaluateScriptString:@"scheme:doc := MPWDocumentScheme scheme."];
    [self loadSmalltalkMethods];
    return self;
}

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
    [self loadSmalltalkMethodsFromDirectory:@"finishLaunching"];
}


@end
