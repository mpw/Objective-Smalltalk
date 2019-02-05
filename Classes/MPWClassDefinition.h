//
//  MPWClassDefinition.h
//  ObjectiveSmalltalk
//
//  Created by Marcel Weiher on 4/12/17.
//
//

#import <ObjectiveSmalltalk/MPWExpression.h>

@interface MPWClassDefinition : MPWExpression

@property (nonatomic, strong) NSString *name;
@property (nonatomic, readonly) Class classToDefine;
@property (nonatomic, strong) NSString *superclassName;
@property (nonatomic, readonly) NSString *superclassNameToUse;

@property (nonatomic, strong) NSArray  *instanceVariableDescriptions;
@property (nonatomic, strong) NSArray  *methods;
@property (nonatomic, strong) NSArray  *propertyPathDefinitions;


@end
