//
//  MPWBlockFilterScheme.h
//  MPWTalk
//
//  Created by Marcel Weiher on 7/12/12.
//
//

#import "MPWGenericScheme.h"
#import <MPWFoundation/MPWFoundation.h>

typedef id (^FilterBlock)(id );

@interface MPWBlockFilterScheme : MPWGenericScheme
{
    MPWScheme *source;
    id identifierFilter,valueFilter;
    
}

idAccessor_h( identifierFilter, setIdentifierFilter)
idAccessor_h( valueFilter, setValueFilter)
objectAccessor_h(MPWScheme, source, setSource)


@end
