//
//  MPWClassDefinition.h
//  ObjectiveSmalltalk
//
//  Created by Marcel Weiher on 4/12/17.
//
//

#import <Foundation/Foundation.h>

@interface MPWClassDefinition : NSObject

@property (nonatomic, strong) NSString *name;
@property (nonatomic, strong) NSString *superclassName;

@property (nonatomic, strong) NSArray  *instanceVariableDescriptions;
@property (nonatomic, strong) NSArray  *methods;


@end
