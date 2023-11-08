//
//  Document.m
//  Smalltalk
//
//  Created by Marcel Weiher on 31.03.19.
//

#import "STDocument.h"
#import "MPWProgramTextView.h"

@interface STDocument(st)

-(IBAction)showWorkspace:(id)sender;

@end


@interface STDocument ()

@property (nonatomic, strong) NSMutableSet *workspaces;

@end

@implementation STDocument

- (nullable instancetype)initWithType:(NSString *)typeName error:(NSError **)outError;
{
    self=[super initWithType:typeName error:outError];
    [self showWorkspace:nil];
    return self;
}


- (instancetype)init {
    self = [super init];
    if (self) {
        self.workspaces = [NSMutableSet set];
    }
    return self;
}

+ (BOOL)autosavesInPlace {
    return YES;
}

-(void)windowWillClose:(NSNotification*)closeNotification
{
    NSWindow *windowToClose=closeNotification.object;
    for ( NSView *workspace in [self.workspaces allObjects] ) {
        if ( workspace.window == windowToClose) {
            [self.workspaces removeObject:workspace];
        }
    }
}



- (NSString *)windowNibName {
    // Override returning the nib file name of the document
    // If you need to use a subclass of NSWindowController or if your document supports multiple NSWindowControllers, you should remove this method and override -makeWindowControllers instead.
    return @"Document";
}


-(MPWProgramTextView*)programTextView
{
    return (MPWProgramTextView*)[[self workspaces] anyObject];       // FIXME: allow only a single text view
}

- (NSData *)dataOfType:(NSString *)typeName error:(NSError **)outError {
    return [[[self programTextView] text] asData];
}

-(BOOL)importOldWindowBasedWorkspace:(NSFileWrapper *)fileWrapper error:(NSError **)outError
{
    NSError *unarchiveError=nil;
    NSFileWrapper *windowsWrapper=[fileWrapper fileWrappers][@"windows"];
    NSData *windowsArchive = [windowsWrapper regularFileContents];
    NSLog(@"windowsArchive length: %ld",(long)windowsArchive.length);
    if ( windowsArchive) {
        NSArray *windowControllers = [NSKeyedUnarchiver unarchivedObjectOfClass:[NSArray class] fromData:windowsArchive  error:&unarchiveError];
        if ( !windowControllers && unarchiveError) {
            NSLog(@"error unarchiving: %@",unarchiveError);
            if ( outError ) {
                *outError=unarchiveError;
            }
        }
        for ( NSWindowController *c in windowControllers) {
            if ( [c respondsToSelector:@selector(view)]) {
                NSView *view=[[c contentViewController] view];
                NSWindow *w = [view openInWindow:@"Workspace"];
                [c setWindow:w];
                NSLog(@"workspace view: %@",view);
                if ( [view respondsToSelector:@selector(setDefaultAttributes)] ) {
                    [view setDefaultAttributes];
                }
                [[view documentView] setCompiler:[self compiler]];
                [self.workspaces addObject:[view documentView]];
            }
            [self addWindowController:c];
        }
    }
    return YES;
}

-(BOOL)readFromFileWrapper:(NSFileWrapper *)fileWrapper ofType:(NSString *)typeName error:(NSError * _Nullable *)outError
{
    if ( [fileWrapper isDirectory]) {
        return [self importOldWindowBasedWorkspace:fileWrapper error:outError];
    } else {
        return [self readFromData:[fileWrapper regularFileContents] ofType:typeName error:outError];
    }

    return YES;
}

- (BOOL)readFromData:(NSData *)data ofType:(NSString *)typeName error:(NSError **)outError {
    NSLog(@"will show workspace");
    [self showWorkspace:nil];
    NSLog(@"did show workspace");
    [[self programTextView] setString:[data stringValue]];
    return YES;
}


@end
