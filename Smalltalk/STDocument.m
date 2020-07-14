//
//  Document.m
//  Smalltalk
//
//  Created by Marcel Weiher on 31.03.19.
//

#import "STDocument.h"
#import "MPWProgramTextView.h"

@interface STDocument ()

@property (nonatomic, strong) NSMutableSet *workspaces;

@end

@implementation STDocument

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
        NSArray *windowControllers = [NSKeyedUnarchiver unarchiveObjectWithData:windowsArchive];
        if ( !windowControllers && unarchiveError) {
            NSLog(@"error unarchiving: %@",unarchiveError);
            if ( outError ) {
                *outError=unarchiveError;
            }
        }
        for ( NSWindowController *c in windowControllers) {
            if ( [c respondsToSelector:@selector(view)]) {
                NSWindow *w = [[c view] openInWindow:@"Workspace"];
                [c setWindow:w];
                NSLog(@"workspace view: %@",[c view]);
                if ( [[c view] respondsToSelector:@selector(setDefaultAttributes)] ) {
                    [[c view] setDefaultAttributes];
                }
                [[[c view] documentView] setCompiler:[self compiler]];
                [self.workspaces addObject:[[c view] documentView]];
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
    [self showWorkspace:nil];
    [[self programTextView] setString:[data stringValue]];
    return YES;
}


@end
