//
//  STPropertyPathDefinition.h
//  ObjectiveSmalltalk
//
//  Created by Marcel Weiher on 8/6/18.
//

#import <MPWFoundation/MPWFoundation.h>

@class MPWReferenceTemplate,STScriptedMethod;

@interface STPropertyPathDefinition : NSObject

@property (nonatomic, strong)  MPWReferenceTemplate* propertyPath;

-(void)setMethod:(STScriptedMethod*)method forVerb:(MPWRESTVerb)verb;
-(STScriptedMethod*)methodForVerb:(MPWRESTVerb)verb;


@end
