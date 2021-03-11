//
//  MPWClassDefinition.h
//  ObjectiveSmalltalk
//
//  Created by Marcel Weiher on 4/12/17.
//
//

#import <ObjectiveSmalltalk/MPWProtocolDefinition.h>

@interface MPWClassDefinition : MPWProtocolDefinition

@property (nonatomic, readonly) Class classToDefine;
@property (nonatomic, strong) NSString *superclassName;
@property (nonatomic, readonly) NSString *superclassNameToUse;

@property (readonly) NSArray *propertyPathGetterDefinitions;
@property (readonly) NSArray *propertyPathSetterDefinitions;

@end
