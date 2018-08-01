//
//  MPWFilterDefinition.h
//  ObjectiveSmalltalk
//
//  Created by Marcel Weiher on 8/1/18.
//

#import <ObjectiveSmalltalk/MPWClassDefinition.h>

@class MPWScriptedMethod;

@interface MPWFilterDefinition : MPWClassDefinition

@property (nonatomic, strong) MPWScriptedMethod *filterMethod;

@end
