//
//  MPWPropertyPathDefinition.h
//  ObjectiveSmalltalk
//
//  Created by Marcel Weiher on 8/6/18.
//

#import <Foundation/Foundation.h>

@class MPWReferenceTemplate,MPWScriptedMethod;

@interface MPWPropertyPathDefinition : NSObject

@property (nonatomic, strong)  MPWReferenceTemplate* propertyPath;
@property (nonatomic, strong)  MPWScriptedMethod *get,*set;

@end
