//
//  SimpleMethodDictDocument.m
//  
//
//  Created by Marcel Weiher on 10/16/11.
//  Copyright (c) 2011 metaobject ltd. All rights reserved.
//

#import "SimpleMethodDictDocument.h"
#import <MPWFoundation/MPWFoundation.h>
#import "MethodDict.h"

@implementation SimpleMethodDictDocument


objectAccessor(MethodDict, dict, setDict)
objectAccessor(NSTextField , methodHeader, setMethodHeader)
objectAccessor(NSTextView, methodBody, setMethodBody)


- (NSString *)windowNibName
{
    // Override returning the nib file name of the document
    // If you need to use a subclass of NSWindowController or if your document supports multiple NSWindowControllers, you should remove this method and override -makeWindowControllers instead.
    return @"MethodDictDocument";
}

- (void)windowControllerDidLoadNib:(NSWindowController *)aController
{
    [super windowControllerDidLoadNib:aController];
    // Add any code here that needs to be executed once the windowController has loaded the document's window.
}

- (NSData *)dataOfType:(NSString *)typeName error:(NSError **)outError
{
    return [[self dict] asXml];
}

- (BOOL)readFromData:(NSData *)data ofType:(NSString *)typeName error:(NSError **)outError
{
    [self setDict:[[[MethodDict alloc] initWithXml:data] autorelease]];
    
    return YES;
}

+ (BOOL)autosavesInPlace
{
    return YES;
}

-(void)setUIForMethodHeader:(NSString*)header body:(NSString*)body
{
//    NSLog(@"will set methodHeader: %@ to %@",[self methodHeader],header);
//    NSLog(@"will set methodBody: %@ to %@",[self methodBody],body);
    [[self methodHeader] setStringValue:header];
    [[self methodBody] setString:body];
    
}

-(void)clearMethodFromUI
{
    [self setUIForMethodHeader:@"" body:@""];
}

-(void)deleteMethodName:(NSString*)methodName forClass:(NSString*)className
{ 
    NSString *oldMethod=[[self dict] methodForClass:className methodName:methodName];
    if ( oldMethod ) {
        NSString *longMethodName = [[self dict] fullNameForMethodName:methodName ofClass:className];        [[[self undoManager] prepareWithInvocationTarget:self] setMethod:oldMethod name:longMethodName  forClass:className];
    }
    [[self dict] deleteMethodName:methodName forClass:className];
    [methodBrowser reloadColumn:0];
    [methodBrowser reloadColumn:1];
    [methodBrowser setPath:[NSString stringWithFormat:@"/%@",className]];
    [self clearMethodFromUI];
}


-(void)setMethod:(NSString*)methodBodyString name:(NSString*)methodName  forClass:(NSString*)className
{
    NSString *oldMethod = [[self dict] methodForClass:className methodName:methodName];
    if ( oldMethod ) {
        [[[self undoManager] prepareWithInvocationTarget:self] setMethod:oldMethod name:methodName  forClass:className];
    } else {
        [[[self undoManager] prepareWithInvocationTarget:self] deleteMethodName:methodName forClass:className];
    }
    [[self dict] setMethod:methodBodyString name:methodName forClass:className];
    NSString *newPath=[NSString stringWithFormat:@"/%@/%@",className,methodName];
    [methodBrowser reloadColumn:0];
    [methodBrowser reloadColumn:1];
    [methodBrowser setPath:newPath];
    [self setUIForMethodHeader:methodName body:methodBodyString];
}



-(void)saveMethodAtPath:(NSString*)path
{
    NSArray *components=[path componentsSeparatedByString:@"/"];
    //    NSLog(@"path: %@, components: %@",path,components);
    if ( [components count]>= 3 ) {
        NSString *className =  [components objectAtIndex:1];
        NSString *methodName = [methodHeader stringValue];
        if ( [methodName length] && [className length] ) {
            [self setMethod:[[[methodBody string] copy] autorelease] name:methodName forClass:className  ];
        }
    }
}

-(void)saveMethodAtCurrentBrowserPath
{
    [self saveMethodAtPath:[methodBrowser path]];
}

-(void)delete:sender
{
    NSString *path=[methodBrowser path];
    NSArray *components=[path componentsSeparatedByString:@"/"];
    if ( [components count] == 3 ) {
        [self deleteMethodName:[components lastObject] forClass:[components objectAtIndex:1]];
    }
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
    NSLog(@"saveDocument");
    [super saveDocument:sender];
    [self performSelector:@selector(upload) withObject:nil afterDelay:0.6];
}


-(IBAction)eval:sender
{
    NSString *statementToEval = [evalText stringValue];
    NSString *cmdTemplate=@"curl -F \"eval=%@\"  \"http://%@:51000/eval\"";
    NSString *serverIP=[address stringValue];
    NSString *cmd=[NSString stringWithFormat:cmdTemplate,statementToEval,serverIP];
    system([cmd UTF8String]);
}

-(void)loadMethodFromPath:(NSString*)path
{
    NSArray *components=[path componentsSeparatedByString:@"/"];
    //    NSLog(@"path: %@, components: %@",path,components);
    if ( [components count]==3 ) {
        NSString *className = [components objectAtIndex:1];
        NSString *shortMethodName = [components lastObject];
        NSString *longMethodName = [[self dict] fullNameForMethodName:shortMethodName ofClass:className];
        [self setUIForMethodHeader:longMethodName body:[[self dict] methodForClass:className methodName:shortMethodName]];
    } else {
        [self clearMethodFromUI];
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
        return [[self dict] classes];
    } else {
        return [[self dict] methodsForClass:anItem];
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
    return ![[[self dict] classes] containsObject:item];
}

/* Return the object value passed to the cell displaying item.
 */
- (id)browser:(NSBrowser *)browser objectValueForItem:(id)item 
{
    return item;
}


@end
