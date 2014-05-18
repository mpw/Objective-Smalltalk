//
//  MPWDocumentScheme.h
//  SketchView
//
//  Created by Marcel Weiher on 6/4/13.
//  Copyright (c) 2013 Marcel Weiher. All rights reserved.
//

#import <ObjectiveSmalltalk/MPWGenericScheme.h>
#import <MPWFoundation/MPWFoundation.h>

@interface MPWDocumentScheme : MPWGenericScheme
{
    NSMutableSet *_referencedDocuments;
}

-(NSSet*)referencedDocuments;

@end
