//
//  MPWBlockFilterScheme.h
//  MPWTalk
//
//  Created by Marcel Weiher on 7/12/12.
//
//

#import <MPWFoundation/MPWFoundation.h>

typedef id (^FilterBlock)(id );

@interface MPWBlockFilterScheme : MPWMappingStore
{
    id identifierFilter,valueFilter;
    
}

idAccessor_h( identifierFilter, setIdentifierFilter)
idAccessor_h( valueFilter, setValueFilter)


@end
