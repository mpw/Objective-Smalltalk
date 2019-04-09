//
//  MPWAppDelegate.m
//  ObjectiveSmalltalkUI
//
//  Created by Marcel Weiher on 31.03.19.
//

#import "MPWAppDelegate.h"
#import "MPWStCompiler.h"

@implementation MPWAppDelegate

-(void)loadSmalltalkMethods
{
    NSBundle *appBundle = [NSBundle bundleForClass:[self class]];
    NSURL *smalltalkDirectory = [[appBundle resourcePath] stringByAppendingPathComponent:@"smalltalk"];
    NSFileManager *fm=[NSFileManager defaultManager];
    for ( NSString *stFile in [fm contentsOfDirectoryAtPath:smalltalkDirectory error:nil] ) {
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

-(instancetype)init
{
    self=[super init];
    self.compiler = [MPWStCompiler compiler];
    [self.compiler bindValue:self toVariableNamed:@"delegate"];
    [self.compiler evaluateScriptString:@"scheme:doc := MPWDocumentScheme scheme."];
    [self loadSmalltalkMethods];
    return self;
}



@end
