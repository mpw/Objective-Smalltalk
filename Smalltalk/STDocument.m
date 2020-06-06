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

- (NSFileWrapper *)_disabled_fileWrapperOfType:(NSString *)typeName
                               error:(NSError * _Nullable *)outError
{
    NSData *windowControllerArchive = [NSKeyedArchiver archivedDataWithRootObject:[self windowControllers] requiringSecureCoding:NO error:nil];

    NSSet *workspaces = [self workspaces];


    NSFileWrapper *windowsWrapper = [[[NSFileWrapper alloc] initRegularFileWithContents:windowControllerArchive] autorelease];
    NSDictionary *wrappers=@{
                             @"windows": windowsWrapper,
                             };
    return [[[NSFileWrapper alloc] initDirectoryWithFileWrappers:wrappers] autorelease];
}

-(MPWProgramTextView*)programTextView
{
    return (MPWProgramTextView*)[[self workspaces] anyObject];       // FIXME: allow only a single text view
}

- (NSData *)dataOfType:(NSString *)typeName error:(NSError **)outError {
    return [[[self programTextView] text] asData];
}

-(BOOL)readFromFileWrapper:(NSFileWrapper *)fileWrapper ofType:(NSString *)typeName error:(NSError * _Nullable *)outError
{
    NSError *unarchiveError=nil;
    if ( [fileWrapper isDirectory]) {
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
    } else {
        NSData *data=[fileWrapper regularFileContents];
        [self showWorkspace:nil];
        [[self programTextView] setString:[data stringValue]];
    }

    return YES;
}

- (BOOL)readFromData:(NSData *)data ofType:(NSString *)typeName error:(NSError **)outError {
    // Insert code here to read your document from the given data of the specified type. If outError != NULL, ensure that you create and set an appropriate error if you return NO.
    // Alternatively, you could remove this method and override -readFromFileWrapper:ofType:error: or -readFromURL:ofType:error: instead.
    // If you do, you should also override -isEntireFileLoaded to return NO if the contents are lazily loaded.
    [NSException raise:@"UnimplementedMethod" format:@"%@ is unimplemented", NSStringFromSelector(_cmd)];
    return YES;
}


@end
