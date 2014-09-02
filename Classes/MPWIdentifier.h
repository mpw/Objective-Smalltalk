//
//  MPWIdentifier.h
//  MPWTalk
//
//  Created by Marcel Weiher on 6.1.10.
//  Copyright 2010 Marcel Weiher. All rights reserved.
//

#import <MPWFoundation/MPWFoundation.h>

@class MPWBinding;

@interface MPWIdentifier : MPWObject {
	id	scheme;
	id	schemeName;
	id	identifierName;
}

idAccessor_h( schemeName, setSchemeName )
idAccessor_h( identifierName, setIdentifierName )
idAccessor_h( scheme, setScheme )

+identifierWithName:(NSString*)name;
-evaluatedIdentifierNameInContext:aContext;

-(MPWBinding*)bindingWithContext:aContext;


@end
