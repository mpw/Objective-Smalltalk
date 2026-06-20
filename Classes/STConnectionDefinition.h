//
//  STConnectionDefinition.h
//  ObjectiveSmalltalk
//
//  Created by Marcel Weiher on 20.05.23.
//

#import <ObjectiveSmalltalk/STExpression.h>

@class MPWInstanceVariable,STScriptedMethod,MPWStructureDefinition;

NS_ASSUME_NONNULL_BEGIN

@interface STConnectionDefinition : STExpression

@property (nonatomic, strong) NSString *name;
@property (nonatomic, strong) MPWStructureDefinition        *structureDefinition;
@property (nonatomic, strong) NSArray<STScriptedMethod*>    *methods;
@property (nonatomic, strong) NSArray<STScriptedMethod*>    *classMethods;
@property (nonatomic, strong) NSArray                       *propertyPathDefinitions;


@end

NS_ASSUME_NONNULL_END
