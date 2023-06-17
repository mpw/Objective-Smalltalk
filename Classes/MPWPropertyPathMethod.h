//
//  MPWPropertyPathGetter.h
//  ObjectiveSmalltalk
//
//  Created by Marcel Weiher on 8/26/18.
//

#import <ObjectiveSmalltalk/MPWAbstractInterpretedMethod.h>

@class MPWPropertyPathDefinition;

@interface MPWPropertyPathMethod : MPWAbstractInterpretedMethod


-(instancetype)initWithPropertyPaths:(NSArray<MPWPropertyPathDefinition*>*)newPaths verb:(MPWRESTVerb)newVerb;


@end
