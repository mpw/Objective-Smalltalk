//
//  STVariableDefinition.h
//  ObjectiveSmalltalk
//
//  Created by Marcel Weiher on 01.07.21.
//

#import <ObjectiveSmalltalk/ObjectiveSmalltalk.h>

NS_ASSUME_NONNULL_BEGIN

@class STTypeDescriptor;

@interface STVariableDefinition : STExpression


-initWithName:(NSString*)newName type:(MPWTypeDefinition*)newType;

@property (nonatomic,strong) STExpression *initializer;

@property (nonatomic,readonly) MPWVariableDefinition *definition;

@property (nonatomic,readonly) NSString *name;
@property (nonatomic,readonly) MPWTypeDefinition *type;


@end

NS_ASSUME_NONNULL_END
