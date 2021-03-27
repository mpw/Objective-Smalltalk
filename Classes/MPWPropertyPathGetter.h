//
//  MPWPropertyPathGetter.h
//  ObjectiveSmalltalk
//
//  Created by Marcel Weiher on 8/26/18.
//

#import <ObjectiveSmalltalk/MPWAbstractInterpretedMethod.h>

@class MPWPropertyPathDefinition;

@interface MPWPropertyPathGetter : MPWAbstractInterpretedMethod

+(instancetype)getterWithPropertyPathDefinitions:(NSArray<MPWPropertyPathDefinition*>*)defs;
-(instancetype)initWithPropertyPathDefinitions:(NSArray<MPWPropertyPathDefinition*>*)defs;

@property (nonatomic,strong) NSArray<MPWPropertyPathDefinition*> *propertyPathDefs;
@property (nonatomic,assign) Class classOfMethod;

@end
