//
//  STIdentifier.h
//  Arch-S
//
//  Created by Marcel Weiher on 6.1.10.
//  Copyright 2010 Marcel Weiher. All rights reserved.
//

#import <MPWFoundation/MPWFoundation.h>
#import <MPWFoundation/MPWGenericIdentifier.h>

@class MPWReference;

@interface STIdentifier : MPWGenericIdentifier {
}


+identifierWithName:(NSString*)name;
-evaluatedIdentifierNameInContext:aContext;

-(MPWReference*)bindingWithContext:aContext;

-resolveRescursiveIdentifierWithContext:aContext;

@end
