//
//  MPWFilterDefinition.h
//  ObjectiveSmalltalk
//
//  Created by Marcel Weiher on 8/1/18.
//

#import <ObjectiveSmalltalk/STClassDefinition.h>

@class MPWScriptedMethod;

@interface MPWFilterDefinition : STClassDefinition

@property (nonatomic, strong) MPWScriptedMethod *filterMethod;

@end
