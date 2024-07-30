//
//  STIdentifier.h
//  Arch-S
//
//  Created by Marcel Weiher on 6.1.10.
//  Copyright 2010 Marcel Weiher. All rights reserved.
//

#import <MPWFoundation/MPWFoundation.h>
#import <MPWFoundation/MPWGenericReference.h>

@class MPWBinding;

@interface STIdentifier : MPWGenericReference {
}


+identifierWithName:(NSString*)name;
-evaluatedIdentifierNameInContext:aContext;

-(MPWBinding*)bindingWithContext:aContext;

-resolveRescursiveIdentifierWithContext:aContext;

@end
