//
//  MPWPropertyPathGetter.h
//  ObjectiveSmalltalk
//
//  Created by Marcel Weiher on 8/26/18.
//

#import <ObjectiveSmalltalk/MPWAbstractInterpretedMethod.h>

@class MPWPropertyPathDefinition;

@interface MPWPropertyPathGetter : MPWAbstractInterpretedMethod


-(instancetype)initWithPropertyPaths:(NSArray<MPWPropertyPathDefinition*>*)newPaths verb:(MPWRESTVerb)newVerb;

@property (nonatomic,assign) Class classOfMethod;
@property (nonatomic, readonly) MPWTemplateMatchingStore *store;

@end
