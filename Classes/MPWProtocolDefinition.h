//
//  MPWProtocolDefinition.h
//  ObjectiveSmalltalk
//
//  Created by Marcel Weiher on 19.02.19.
//

#import <ObjectiveSmalltalk/MPWExpression.h>

@interface MPWProtocolDefinition : MPWExpression

@property (nonatomic, strong) NSString *name;

@property (nonatomic, strong) NSArray  *instanceVariableDescriptions;
@property (nonatomic, strong) NSArray  *methods;
@property (nonatomic, strong) NSArray  *propertyPathDefinitions;


-(void)defineProtocol;

@end

