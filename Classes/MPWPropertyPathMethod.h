//
//  MPWPropertyPathGetter.h
//  ObjectiveSmalltalk
//
//  Created by Marcel Weiher on 8/26/18.
//

#import <ObjectiveSmalltalk/MPWAbstractInterpretedMethod.h>
#import <MPWFoundation/MPWFoundation.h>
#import <MPWFoundation/MPWTemplateMatchingStore.h>

@class STPropertyPathDefinition;

@interface MPWPropertyPathMethod : MPWAbstractInterpretedMethod


-(instancetype)initWithPropertyPaths:(PropertyPathDef*)newPaths count:(int)count verb:(MPWRESTVerb)verb;


@end
