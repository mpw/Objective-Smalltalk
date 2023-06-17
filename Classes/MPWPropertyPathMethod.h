//
//  MPWPropertyPathGetter.h
//  ObjectiveSmalltalk
//
//  Created by Marcel Weiher on 8/26/18.
//

#import <ObjectiveSmalltalk/MPWAbstractInterpretedMethod.h>
#import <MPWFoundation/MPWFoundation.h>
#import <MPWFoundation/MPWTemplateMatchingStore.h>

@class MPWPropertyPathDefinition;

@interface MPWPropertyPathMethod : MPWAbstractInterpretedMethod


-(instancetype)initWithPropertyPaths:(PropertyPathDefs*)newPaths;


@end
