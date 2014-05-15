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

-(void)clearRefs
{
    [self setReferencedDocuments:[NSMutableSet set]];
}

-(NSSet*)referencedDocuments
{
    return [[[self _referencedDocuments] copy] autorelease];
}

-(id)init
{
    self=[super init];
    [self clearRefs];
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
        return [[NSDocumentController sharedDocumentController] currentDocument];
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
    [super dealloc];
}
@end
