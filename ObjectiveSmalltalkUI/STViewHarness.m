//
//  STViewHarness.m
//  ObjectiveSmalltalkUI
//
//  Created by Marcel Weiher on 18.03.26.
//

#import "STViewHarness.h"
#import <MPWFoundationUI/MPWFoundationUI.h>
// #import "MPWWindowController.h"

@interface STViewHarness ()

@property (nonatomic, strong ) NSView *contentView;
@property (nonatomic, assign ) bool autoredisplay;

@end

@implementation STViewHarness


-(void)redisplayDisplayingErrors
{
    NSString *errorMsg = @"";
    NSException *error = nil;
    @try {
        [self.contentView display];
        if ( [self.contentView respondsToSelector:@selector(lastException)] ) {
            error = [(MPWView*)self.contentView lastException];
        }
    } @catch ( NSException *e ) {
        error = e;
    }
    if (error ) {
        errorMsg = [error description];
    }
    [self.logView setString:errorMsg];
}

-(IBAction)triggerRedisplay:(id)sender
{
    [self redisplayDisplayingErrors];
}

-(void)didCompileClass:className
{
    NSLog(@"didCompileClass: %@",className);
    [self redisplayDisplayingErrors];
}

-(instancetype)initWithView:newContentView
{
    self = [super initWithNibName:@"STViewHarness" bundle:[NSBundle bundleForClass:[self class]]];
    self.contentView = newContentView;
    [self view];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didCompileClass:) name:@"ClassCompiled" object:nil];
    NSLog(@"STViewHarness: %p",self);
    return self;
}

-(void)awakeFromNib
{
    [super awakeFromNib];
    self.view.autoresizingMask = self.slotForContentView.autoresizingMask;
    [self.slotForContentView addSubview:self.contentView];
}

-openInWindow:(NSString*)windowName
{
    NSDocument *doc = [[NSDocumentController sharedDocumentController]   currentDocument];
    NSWindow *window = [self.view openInWindow:windowName];
    MPWWindowController *windowController=[[[MPWWindowController alloc] initWithWindow:window] autorelease];
    windowController.viewController=self;
    [doc addWindowController:windowController];
    return window;
}


@end



@implementation NSView(inHarness)

-inHarness
{
    STViewHarness *harness = [[[STViewHarness alloc] initWithView:self] autorelease];
    return harness;
}

@end
