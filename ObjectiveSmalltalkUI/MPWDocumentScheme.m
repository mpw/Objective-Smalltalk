//
//  MPWDocumentScheme.m
//  SketchView
//
//  Created by Marcel Weiher on 6/4/13.
//  Copyright (c) 2013 Marcel Weiher. All rights reserved.
//

#import "MPWDocumentScheme.h"
#import <Cocoa/Cocoa.h>
#import <MPWFoundation/MPWFoundation.h>

@implementation MPWDocumentScheme

objectAccessor(NSMutableSet, _referencedDocuments, setReferencedDocuments)
idAccessor(currentDocument, setCurrentDocument)

-(void)clearRefs
{
    [self setReferencedDocuments:[NSMutableSet set]];
}

-(NSSet*)referencedDocuments
{
    return [[[self _referencedDocuments] copy] autorelease];
}

-externalCurrentDoc
{
    return [[NSDocumentController sharedDocumentController] currentDocument];
}


-(void)keyWindowChangedAfterDelay
{
    NSLog(@"keyWindowChanged");
    id newCurrentDoc = [self externalCurrentDoc];
    NSLog(@"newCurrentDoc: %@",newCurrentDoc);
    if ( newCurrentDoc) {
        [self setCurrentDocument:newCurrentDoc];
    }
}

-(void)keyWindowChanged
{
    [[self afterDelay:0.001] keyWindowChangedAfterDelay];
}

-currentDoc
{
    id doc=[self externalCurrentDoc];
    NSLog(@"external: %@",doc);
    if (!doc) {
        doc=[self currentDocument];
        NSLog(@"remembered: %@",doc);
    }
    return doc;
}

-(id)init
{
    self=[super init];
    [self clearRefs];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyWindowChanged) name:NSWindowDidBecomeMainNotification object:nil];
    return self;
}

-(id)docForName:(NSString*)lookupName
{
    for ( NSDocument *doc in [[NSDocumentController sharedDocumentController] documents]){
        NSString *docName=[doc displayName];
        if ( [docName isEqual:lookupName]) {
            return doc;
        }
    }
    return nil;
}



-(id)valueForBinding:(MPWGenericBinding *)aBinding
{
    NSString *path=[aBinding name];
    NSLog(@"path: %@",path);
    if ( [path isEqualTo:@"."] || [path isEqualTo:@"./"]) {
        return [self currentDoc];
    }
    NSArray *lookupPath=[[aBinding name] componentsSeparatedByString:@"/"];
    if ( [lookupPath count] > 1 ) {
        lookupPath=[lookupPath subarrayWithRange:NSMakeRange(1, [lookupPath count]-1)];
        
    }
    
    NSString *docName=[lookupPath objectAtIndex:0];
    id doc=[self docForName:docName];
    if ( doc ) {
        [[self _referencedDocuments] addObject:doc];
    } else {
        NSLog(@"doc not found: %@",docName);
    }
    return doc;
}

-(void)dealloc
{
    [_referencedDocuments release];
    [currentDocument release];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [super dealloc];
}
@end
