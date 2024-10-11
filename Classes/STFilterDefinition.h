//
//  STFilterDefinition.h
//  ObjectiveSmalltalk
//
//  Created by Marcel Weiher on 8/1/18.
//

#import <ObjectiveSmalltalk/STClassDefinition.h>

@class STScriptedMethod;

@interface STFilterDefinition : STClassDefinition

@property (nonatomic, strong) STScriptedMethod *filterMethod;

@end
