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
    return NO;
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

-(id <MPWStorage>)workspacesStore
{
    return [self.bundle storeForSubDir:@"Workspaces"];
}

-(BOOL)autosavesDrafts
{
    return NO;
}


//  FIXME:  this is hack to work around the fact that STBundles currently only support saving in-place
//          but NSDocument expects to safely write somewhere else and the move/copy
//          It just writes to the original URL

-(BOOL)writeSafelyToURL:(NSURL *)url ofType:(NSString *)type forSaveOperation:(NSSaveOperationType)op error:(NSError **)outError
{
    if ( self.bundle) {
        [self.bundle save];
        id <MPWStorage> workspaces = [self workspacesStore];
        workspaces[@"main.st"] = [[[self programTextView] string] asData];
        NSLog(@"did save to %@",url);
        return YES;
    } else {
        return [[[[self programTextView] text] asData] writeToURL:url atomically:YES];
    }
}

-(BOOL)validateToolbarItem:(NSToolbarItem *)item
{
//    NSLog(@"validate: %@ %@",item.itemIdentifier,item);
    if ( [item.itemIdentifier isEqual:LinkDependencies] ) {
        return !self.bundle.frameworksLoaded;
    } else if ( [item.itemIdentifier isEqual:Compile] ) {
        return !self.bundle.sourcesCompiled;
    }
    return YES;
}

static NSString *LinkDependencies = @"LinkDependencies";
static NSString *Compile = @"Compile";
static NSString *Browse = @"Browse";


- (NSArray *) toolbarAllowedItemIdentifiers: (NSToolbar *) toolbar {
//    NSLog(@"toolbarAllowedItemIdentifiers: %@",toolbar);
    return @[
        NSToolbarToggleInspectorItemIdentifier,
        NSToolbarShowColorsItemIdentifier,
        Compile, LinkDependencies, Browse,
        NSToolbarFlexibleSpaceItemIdentifier,
            NSToolbarSpaceItemIdentifier,
            NSToolbarSeparatorItemIdentifier,
    ];
}

- (NSArray *) toolbarDefaultItemIdentifiers: (NSToolbar *)toolbar
{
//    NSLog(@"toolbarDefaultItemIdentifiers %@",toolbar);
    NSArray *items = @[
        Compile, LinkDependencies, Browse,
    ];
//    NSLog(@"toolbarDefaultItemIdentifiers items: %@",items);
    return items;
}

- (void) toolbarWillAddItem:(NSNotification *) notification{
//    NSLog(@"will add item: %@",notification.object);
}

- (BOOL) toolbar:(NSToolbar *) toolbar
  itemIdentifier:(NSToolbarItemIdentifier) itemIdentifier
canBeInsertedAtIndex:(NSInteger) index
{
//    NSLog(@"canBeInserted: %@",itemIdentifier);
    return YES;
}

- (NSToolbarItem *)toolbar:(NSToolbar *)toolbar
     itemForItemIdentifier:(NSString *)itemIdentifier
 willBeInsertedIntoToolbar:(BOOL)flag
{
    NSToolbarItem *toolbarItem = [[NSToolbarItem alloc] initWithItemIdentifier:itemIdentifier];
    
    if ([itemIdentifier isEqualTo:Compile]) {
        [toolbarItem setLabel:@"Compile"];
//        [toolbarItem setPaletteLabel:[toolbarItem label]];
        [toolbarItem setToolTip:@"Compile all code"];
        [toolbarItem setTarget:self];
        [toolbarItem setAction:@selector(compileAllSourceFiles)];
    }  else if ([itemIdentifier isEqualTo:LinkDependencies]) {
        [toolbarItem setLabel:@"Link"];
        //        [toolbarItem setPaletteLabel:[toolbarItem label]];
        [toolbarItem setToolTip:@"Link all dependenies"];
        [toolbarItem setTarget:self];
        [toolbarItem setAction:@selector(linkDependencies)];
    }  else if ([itemIdentifier isEqualTo:Browse]) {
        [toolbarItem setLabel:@"Browse"];
        //        [toolbarItem setPaletteLabel:[toolbarItem label]];
        [toolbarItem setToolTip:@"Browse source code"];
        [toolbarItem setTarget:self];
        [toolbarItem setAction:@selector(openClassBrowser:)];
    }
    NSLog(@"toolbar item: %@",toolbarItem);
    return [toolbarItem autorelease];
}

-(void)compileAllSourceFiles
{
    [self.bundle compileAllSourceFiles];
}

-(void)linkDependencies
{
    [self.bundle loadFrameworks];
}

-(void)configureToolbar
{
    NSToolbar *toolbar = [[[NSToolbar alloc] initWithIdentifier:@"main"] autorelease];
    toolbar.delegate = self;

    [[[[self windowControllers] firstObject] window] setToolbar:toolbar];
    NSLog(@"toolbar: %@",toolbar);
}

- (BOOL)readBundle:(NSString *)path ofType:(NSString *)typeName error:(NSError **)outError
{
    self.bundle = [STBundle bundleWithPath:path];
    STCompiler* compiler = [[[NSApplication sharedApplication] delegate] compiler];
    [self.bundle configureInterpreter:compiler];
    [compiler evaluateScriptString:@"scheme:builder setPrefixes: [ 'MPW' , 'ST']. "];
    [self.bundle setInterpreter:compiler];
    [compiler bindValue:self.bundle toVariableNamed:@"bundle"];
    NSLog(@"path: %@",path);
    NSLog(@"bundle: %@",self.bundle);
    [self showWorkspace:nil];
    [self configureToolbar];
    
    id <MPWStorage> workspaces = [self workspacesStore];
    [[self programTextView] setString:[workspaces[@"main.st"] stringValue]];
    return YES;
}

-(IBAction)openClassBrowser:sender
{
    [[self.bundle classBrowser] openInWindow:@"Class Browser"];
}

-(BOOL)readFromURL:(NSURL *)url ofType:(NSString *)typeName error:(NSError * _Nullable *)outError
{
    if ( [typeName isEqualToString:@"Software IC"]) {
        return [self readBundle:[url path] ofType:typeName error:outError];
    } else {
        return [self readFromData:[NSData dataWithContentsOfURL:url] ofType:typeName error:outError];
    }
    
}

- (BOOL)readFromData:(NSData *)data ofType:(NSString *)typeName error:(NSError **)outError {
    [self showWorkspace:nil];
    [[self programTextView] setString:[data stringValue]];
    return YES;
}


@end
