//
//  stsh_ui.m
//  stui
//
//  Created by Marcel Weiher on 20.08.22.
//


#import <MPWFoundationUI/MPWFoundationUI.h>
#import "STShell.h"
#import <ObjectiveSmalltalkUI/ObjectiveSmalltalkUI.h>

@interface MPWStshUI : STShell

@property (nonatomic, strong) CLIApp *app;

@end



int main (int argc, const char *argv[])
{
    [[NSAutoreleasePool alloc] init];
    NSMutableArray *args=[NSMutableArray array];
    for (int i=1;i<argc;i++) {
        [args addObject:[NSString stringWithUTF8String:argv[i]]];
    }
    STShell *stsh=[[[MPWStshUI alloc] initWithArgs:args] autorelease];
    NSData* initCode = [[STTextField class] frameworkResource:@"AppKitInit" category:@"st"];
    NSData *data=[[STTextField class] frameworkResource:@"appkit-enums" category:@"json"];
    NSDictionary *dict=[NSJSONSerialization JSONObjectWithData:data options:0 error:nil];
    MPWDictStore *enumStore=[MPWDictStore storeWithDictionary:dict];
    STCompiler *compiler=[stsh evaluator];
    [[compiler schemes] setSchemeHandler:enumStore forSchemeName:@"c"];
    [[compiler schemes] setSchemeHandler:[MPWColorStore store] forSchemeName:@"color"];
    [[compiler schemes] setSchemeHandler:[MPWFontStore store] forSchemeName:@"font"];
    [compiler compileAndEvaluate:[initCode stringValue]];

//    NSLog(@"initCode:\n%@",[initCode stringValue]);
    [stsh setCommandName:[NSString stringWithUTF8String:argv[0]]];
    [stsh run];
    exit(0);       // insure the process exit status is 0
    return 0;      // ...and make main fit the ANSI spec.
}

@implementation MPWStshUI

-(void)setEvaluator:newEval
{
    [super setEvaluator:newEval];
    self.app = [CLIApp sharedApplication];
    if ( self.app ) {
        [newEval bindValue:self.app toVariableNamed:@"app"];
    }
}

-(void)evaluateReturnValue_disabled:value
{
    [self.app runFromCLI:value];
}

@end


@implementation NSWindow(running)

-main:args
{
    NSLog(@"window main:");
    [[CLIApp sharedApplication] runFromCLI:self];
    return @(0);
}

@end
