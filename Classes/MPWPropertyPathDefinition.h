//
//  MPWPropertyPathDefinition.h
//  ObjectiveSmalltalk
//
//  Created by Marcel Weiher on 8/6/18.
//

#import <MPWFoundation/MPWFoundation.h>

@class MPWReferenceTemplate,MPWScriptedMethod;

@interface MPWPropertyPathDefinition : NSObject

@property (nonatomic, strong)  MPWReferenceTemplate* propertyPath;

-(void)setMethod:(MPWScriptedMethod*)method forVerb:(MPWRESTVerb)verb;
-(MPWScriptedMethod*)methodForVerb:(MPWRESTVerb)verb;


@end
