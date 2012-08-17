//
//  MPWFilterScheme.h
//  MPWTalk
//
//  Created by Marcel Weiher on 8/8/12.
//
//

#import <ObjectiveSmalltalk/MPWGenericScheme.h>
#import <MPWFoundation/MPWFoundation.h>

@interface MPWFilterScheme : MPWGenericScheme
{
    MPWScheme *source;
}

objectAccessor_h(MPWScheme, source, setSource)

@end
