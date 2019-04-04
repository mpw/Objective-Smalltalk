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


- (NSData *)dataOfType:(NSString *)typeName error:(NSError **)outError {
    return [[(MPWProgramTextView*)[[self workspaces] anyObject] text] asData];
}


- (BOOL)readFromData:(NSData *)data ofType:(NSString *)typeName error:(NSError **)outError {
    // Insert code here to read your document from the given data of the specified type. If outError != NULL, ensure that you create and set an appropriate error if you return NO.
    // Alternatively, you could remove this method and override -readFromFileWrapper:ofType:error: or -readFromURL:ofType:error: instead.
    // If you do, you should also override -isEntireFileLoaded to return NO if the contents are lazily loaded.
    [NSException raise:@"UnimplementedMethod" format:@"%@ is unimplemented", NSStringFromSelector(_cmd)];
    return YES;
}


@end
