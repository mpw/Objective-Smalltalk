//
//  STClassDefinition.h
//  ObjectiveSmalltalk
//
//  Created by Marcel Weiher on 4/12/17.
//
//

#import <ObjectiveSmalltalk/STProtocolDefinition.h>

@interface STClassDefinition : STProtocolDefinition

@property (nonatomic, readonly) Class classToDefine;
@property (nonatomic, strong) NSString *superclassName;
@property (nonatomic, readonly) NSString *superclassNameToUse;

@property (readonly) NSArray *propertyPathImplementationMethods;
@property (readonly) NSArray *allImplementationMethods;

-(PropertyPathDefs*)propertyPathDefsForVerb:(MPWRESTVerb)thisVerb;
-(BOOL)defineJustTheClass;



@end
