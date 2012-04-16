//
//  SimpleMethodDictDocument.m
//  
//
//  Created by Marcel Weiher on 10/16/11.
//  Copyright (c) 2012 metaobject ltd. All rights reserved.
//

#import "SimpleMethodDictDocument.h"
#import <MPWFoundation/MPWFoundation.h>
#import "MethodDict.h"

@implementation SimpleMethodDictDocument

static const NSString *UNIQUEID=@"uniqueID";
static const NSString *METHODDICT=@"methodDict";

objectAccessor(MethodDict, methodDict, setMethodDict)
objectAccessor(NSTextField , methodHeader, setMethodHeader)
objectAccessor(NSTextView, methodBody, setMethodBody)
objectAccessor(NSString, uniqueID, setUniqueID)

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
    NSDictionary *methodSubDict=[[self methodDict] dict];
    NSDictionary *dict=[NSDictionary dictionaryWithObjectsAndKeys:
                        methodSubDict,METHODDICT,
                        [self uniqueID],UNIQUEID,
                        nil];
    NSData *data=[NSPropertyListSerialization dataFromPropertyList:dict format:NSPropertyListXMLFormat_v1_0 errorDescription:nil];

    return data;
}

- (BOOL)readFromData:(NSData *)data ofType:(NSString *)typeName error:(NSError **)outError
{
    NSMutableDictionary *d=[NSPropertyListSerialization propertyListFromData:data mutabilityOption:NSPropertyListMutableContainers format:nil errorDescription:nil];
    NSDictionary *methodSubDict=d;
    if ( [d objectForKey:UNIQUEID] ) {
        methodSubDict=[d objectForKey:METHODDICT];
        [self setUniqueID:[d objectForKey:UNIQUEID]];
    } else {
        [self setUniqueID:[[NSProcessInfo processInfo] globallyUniqueString]];
    }
    [self setMethodDict:[[[MethodDict alloc] initWithDict:methodSubDict] autorelease]];
    
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
    NSString *oldMethod=[[self methodDict] methodForClass:className methodName:methodName];
    if ( oldMethod ) {
        NSString *longMethodName = [[self methodDict] fullNameForMethodName:methodName ofClass:className];        [[[self undoManager] prepareWithInvocationTarget:self] setMethod:oldMethod name:longMethodName  forClass:className];
    }
    [[self methodDict] deleteMethodName:methodName forClass:className];
    [methodBrowser reloadColumn:0];
    [methodBrowser reloadColumn:1];
    [methodBrowser setPath:[NSString stringWithFormat:@"/%@",className]];
    [self clearMethodFromUI];
}


-(void)setMethod:(NSString*)methodBodyString name:(NSString*)methodName  forClass:(NSString*)className
{
    NSString *oldMethod = [[self methodDict] methodForClass:className methodName:methodName];
    if ( oldMethod ) {
        [[[self undoManager] prepareWithInvocationTarget:self] setMethod:oldMethod name:methodName  forClass:className];
    } else {
        [[[self undoManager] prepareWithInvocationTarget:self] deleteMethodName:methodName forClass:className];
    }
    [[self methodDict] setMethod:methodBodyString name:methodName forClass:className];
    NSString *newPath=[NSString stringWithFormat:@"/%@/%@",className,methodName];
    [methodBrowser reloadColumn:0];
    [methodBrowser reloadColumn:1];
    [methodBrowser setPath:newPath];
    [self setUIForMethodHeader:methodName body:methodBodyString];
}

-(NSString*)methodBodyString
{
    return [[[methodBody string] copy] autorelease];
}

-(void)saveMethodAtPath:(NSString*)path
{
    NSArray *components=[path componentsSeparatedByString:@"/"];
    //    NSLog(@"path: %@, components: %@",path,components);
    if ( [components count]>= 2 ) {
        NSString *className =  [components objectAtIndex:1];
        NSString *methodName = [methodHeader stringValue];
        if ( [methodName length] && [className length] ) {
            [self setMethod:[self methodBodyString] name:methodName forClass:className  ];
        }
    }
}


-(void)saveCurrentMethod
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

-(NSString*)determineServer
{
    
}


- (void)upload {
    NSString *cmdTemplate=@"cd %@; curl -F 'methods=@methods.plist'  \"%@methods\"";
    NSLog(@"commandtemplate: '%@'",cmdTemplate);
    NSString *dir=[[[self fileURL] path] stringByDeletingLastPathComponent];
    NSString *cmd=[NSString stringWithFormat:cmdTemplate,dir,[self baseURL]];
    NSLog(@"cmd = '%@'",cmd);
    system([cmd UTF8String]);
}

-(void)saveDocument:(id)sender
{
    NSString *browserPath = [[[methodBrowser path] retain] autorelease];
    [self saveCurrentMethod];
    NSLog(@"saveDocument");
    [super saveDocument:sender];
    [self performSelector:@selector(upload) withObject:nil afterDelay:0.6];
    [methodBrowser setPath:browserPath];
}


-(IBAction)eval:sender
{
    NSString *statementToEval = [evalText stringValue];
    NSString *cmdTemplate=@"curl -F \"eval=%@\"  \"%@eval\"";

    NSString *cmd=[NSString stringWithFormat:cmdTemplate,statementToEval,[self baseURL]];
    NSLog(@"cmd = '%@'",cmd);
    system([cmd UTF8String]);
}

-(void)loadMethodFromPath:(NSString*)path
{
    NSArray *components=[path componentsSeparatedByString:@"/"];
    //    NSLog(@"path: %@, components: %@",path,components);
    if ( [components count]==3 ) {
        NSString *className = [components objectAtIndex:1];
        NSString *shortMethodName = [components lastObject];
        NSString *longMethodName = [[self methodDict] fullNameForMethodName:shortMethodName ofClass:className];
        [self setUIForMethodHeader:longMethodName body:[[self methodDict] methodForClass:className methodName:shortMethodName]];
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
        return [[self methodDict] classes];
    } else {
        return [[self methodDict] methodsForClass:anItem];
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
    return ![[[self methodDict] classes] containsObject:item];
}

/* Return the object value passed to the cell displaying item.
 */
- (id)browser:(NSBrowser *)browser objectValueForItem:(id)item 
{
    return item;
}


@end
