//
//  MPWProtocolDefinition.h
//  ObjectiveSmalltalk
//
//  Created by Marcel Weiher on 19.02.19.
//

#import <ObjectiveSmalltalk/STConnectionDefinition.h>

@class MPWInstanceVariable,MPWScriptedMethod;

@interface MPWProtocolDefinition : STConnectionDefinition



-(void)defineProtocol;

@end

