//
//  MethodDict.m
//  MethodEditor
//
//  Created by Marcel Weiher on 9/25/11.
//  Copyright 2011 metaobject ltd. All rights reserved.
//

#import "MethodDict.h"
#import <MPWFoundation/MPWFoundation.h>

@implementation MethodDict

objectAccessor(NSMutableDictionary, dict, setDict)

- (id)init
{
    self = [super init];
    if (self) {
        // Add your subclass-specific initialization here.
        // If an error occurs here, return nil.
    }
    return self;
}

- (NSString *)windowNibName
{
    // Override returning the nib file name of the document
    // If you need to use a subclass of NSWindowController or if your document supports multiple NSWindowControllers, you should remove this method and override -makeWindowControllers instead.
    return @"MethodDict";
}

- (void)windowControllerDidLoadNib:(NSWindowController *)aController
{
    [super windowControllerDidLoadNib:aController];
    // Add any code here that needs to be executed once the windowController has loaded the document's window.
}

- (NSData *)dataOfType:(NSString *)typeName error:(NSError **)outError
{
    NSData *data=[NSPropertyListSerialization dataFromPropertyList:[self dict] format:NSPropertyListXMLFormat_v1_0 errorDescription:nil];
    return data;
}

- (BOOL)readFromData:(NSData *)data ofType:(NSString *)typeName error:(NSError **)outError
{
    NSDictionary *d=[NSPropertyListSerialization propertyListFromData:data mutabilityOption:NSPropertyListMutableContainers format:nil errorDescription:nil];
    [self setDict:d];
    
    return YES;
}

+ (BOOL)autosavesInPlace
{
    return YES;
}

-(NSArray*)classes
{
    return [[self dict] allKeys];
}

-(NSArray*)methodsForClass:(NSString*)className
{
    return [[[self dict] objectForKey:className] allKeys];
}

-(NSString*)methodForClass:(NSString*)className methodName:(NSString*)methodName
{
    return [[[self dict] objectForKey:className] objectForKey:methodName];
}

-(void)setMethod:(NSString*)methodBody forClass:(NSString*)className methodName:(NSString*)methodName
{
    NSMutableDictionary *perClassDict = [[self dict] objectForKey:className];
    if ( !perClassDict ) {
        perClassDict=[NSMutableDictionary dictionary];
        [[self dict] setObject:perClassDict forKey:className];
    }
    [perClassDict setObject:methodBody forKey:methodName];
}

-(void)saveMethodAtPath:(NSString*)path
{
    NSArray *components=[path componentsSeparatedByString:@"/"];
    NSLog(@"path: %@, components: %@",path,components);
    if ( [components count]>= 2 ) {
        [self setMethod:[[[methodBody string] copy] autorelease] forClass:[components objectAtIndex:1] methodName:[methodHeader stringValue]];
        if ( ![[methodHeader stringValue] isEqualToString:[components lastObject]] ) {
            [methodBrowser reloadColumn:1];
        }
    }
}

-(void)saveMethodAtCurrentBrowserPath
{
    [self saveMethodAtPath:[methodBrowser path]];
}



- (void)upload {
    NSString *cmdTemplate=@"cd %@; curl -F 'methods=@methods.plist'  \"http://%@:51000/methods\"";
    NSString *dir=[[[self fileURL] path] stringByDeletingLastPathComponent];
    NSString *serverIP=[address stringValue];
    NSString *cmd=[NSString stringWithFormat:cmdTemplate,dir,serverIP];
    system([cmd UTF8String]);
}

-(void)saveDocument:(id)sender
{
    [self saveMethodAtCurrentBrowserPath];
    [super saveDocument:sender];
    [self performSelector:@selector(upload) withObject:nil afterDelay:0.6];
}


-(IBAction)eval:sender
{
    NSString *statementToEval = [evalText stringValue];
    NSString *cmdTemplate=@"curl -F \"eval=%@\"  \"http://%@:51000/eval\"";
    NSString *dir=[[[self fileURL] path] stringByDeletingLastPathComponent];
    NSString *serverIP=[address stringValue];
    NSString *cmd=[NSString stringWithFormat:cmdTemplate,statementToEval,serverIP];
    system([cmd UTF8String]);
}

-(void)loadMethodFromPath:(NSString*)path
{
    NSArray *components=[path componentsSeparatedByString:@"/"];
    NSLog(@"path: %@, components: %@",path,components);
    if ( [components count]==3 ) {
        [methodHeader setStringValue:[components lastObject]];
        [methodBody setString:[self methodForClass:[components objectAtIndex:1] methodName:[components lastObject]]];
    }
}

-(IBAction)didSelect:(NSBrowser*)sender
{
    [self loadMethodFromPath:[sender path]];
}

//---- browser delegate 

-(NSArray*)listForItem:anItem
{
    if ( !anItem ) {
        return [self classes];
    } else {
        return [self methodsForClass:anItem];
    }
    return nil;
}

- (NSInteger)browser:(NSBrowser *)browser numberOfChildrenOfItem:(id)item 
{
    return [[self listForItem:item] count];
}

- (id)browser:(NSBrowser *)browser child:(NSInteger)index ofItem:(id)item 
{
    return [[self listForItem:item] objectAtIndex:index];
}



/* Return whether item should be shown as a leaf item; that is, an item that can not be expanded into another column. Returning NO does not prevent you from returning 0 from -browser:numberOfChildrenOfItem:.
 */
- (BOOL)browser:(NSBrowser *)browser isLeafItem:(id)item
{
    return ![[self classes] containsObject:item];
}

/* Return the object value passed to the cell displaying item.
 */
- (id)browser:(NSBrowser *)browser objectValueForItem:(id)item 
{
    return item;
}



@end
