//
//  MPWProtocolDefinition.h
//  ObjectiveSmalltalk
//
//  Created by Marcel Weiher on 19.02.19.
//

#import <ObjectiveSmalltalk/MPWExpression.h>

@class MPWInstanceVariable,MPWScriptedMethod;

@interface MPWProtocolDefinition : MPWExpression

@property (nonatomic, strong) NSString *name;

@property (nonatomic, strong) NSArray<MPWInstanceVariable*>  *instanceVariableDescriptions;
@property (nonatomic, strong) NSArray<MPWScriptedMethod*>    *methods;
@property (nonatomic, strong) NSArray<MPWScriptedMethod*>    *classMethods;
@property (nonatomic, strong) NSArray                        *propertyPathDefinitions;


-(void)defineProtocol;

@end

