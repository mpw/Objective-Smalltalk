//
//  Document.m
//  Smalltalk
//
//  Created by Marcel Weiher on 31.03.19.
//

#import "STDocument.h"
#import "STProgramTextView.h"
#import <ObjectiveSmalltalk/ObjectiveSmalltalk.h>

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


-(STProgramTextView*)programTextView
{
    return (STProgramTextView*)[[self workspaces] anyObject];       // FIXME: allow only a single text view
}

- (NSData *)dataOfType:(NSString *)typeName error:(NSError **)outError {
    return [[[self programTextView] text] asData];
}

- (BOOL)readBundle:(NSString *)path ofType:(NSString *)typeName error:(NSError **)outError
{
    id bundle = [STBundle bundleWithPath:path];
    NSLog(@"path: %@",path);
    NSLog(@"bundle: %@",bundle);
    [self showWorkspace:nil];
    id <MPWStorage> workspaces = [bundle storeForSubDir:@"Workspaces"];
    NSLog(@"store: %@",workspaces);
    [[self programTextView] setString:[workspaces[@"main.st"] stringValue]];
    return YES;
}

-(BOOL)readFromURL:(NSURL *)url ofType:(NSString *)typeName error:(NSError * _Nullable *)outError
{
    if ( [typeName isEqualToString:@"Software IC"]) {
        return [self readBundle:[url path] ofType:typeName error:outError];
    } else {
        return [self readFromData:[NSData dataWithContentsOfURL:url] ofType:typeName error:outError];
    }
    
}

//
//-(BOOL)readFromFileWrapper:(NSFileWrapper *)fileWrapper ofType:(NSString *)typeName error:(NSError * _Nullable *)outError
//{
//    NSLog(@"typeName: %@",typeName);
//    if ( [fileWrapper isDirectory]  && [typeName isEqualToString:@"Software IC"]) {
//        return [self readBundle:[fileWrapper path] ofType:typeName error:outError];
//    } else {
//        return [self readFromData:[fileWrapper regularFileContents] ofType:typeName error:outError];
//    }
//
//    return YES;
//}
//
- (BOOL)readFromData:(NSData *)data ofType:(NSString *)typeName error:(NSError **)outError {
    NSLog(@"will show workspace");
    [self showWorkspace:nil];
    NSLog(@"did show workspace");
    [[self programTextView] setString:[data stringValue]];
    return YES;
}


@end
