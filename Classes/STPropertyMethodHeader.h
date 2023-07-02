//
//  STPropertyMethodHeader.h
//  ObjectiveSmalltalk
//
//  Created by Marcel Weiher on 02.07.23.
//

#import <ObjectiveSmalltalk/ObjectiveSmalltalk.h>

NS_ASSUME_NONNULL_BEGIN

@interface STPropertyMethodHeader : MPWMethodHeader

-(instancetype)initWithTemplate:(MPWReferenceTemplate*)template verb:(MPWRESTVerb)verb;

@end

NS_ASSUME_NONNULL_END
