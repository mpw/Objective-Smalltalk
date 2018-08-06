//
//  MPWPropertyPathDefinition.h
//  ObjectiveSmalltalk
//
//  Created by Marcel Weiher on 8/6/18.
//

#import <Foundation/Foundation.h>

@class MPWPropertyPath;

@interface MPWPropertyPathDefinition : NSObject

@property (nonatomic, strong)  MPWPropertyPath* propertyPath;
@property (nonatomic, strong)  id body;

@end
