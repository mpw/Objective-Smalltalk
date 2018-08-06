//
//  MPWPropertyPathDefinition.h
//  ObjectiveSmalltalk
//
//  Created by Marcel Weiher on 8/6/18.
//

#import <Foundation/Foundation.h>

@class MPWIdentifier;

@interface MPWPropertyPathDefinition : NSObject

@property (nonatomic, strong)  MPWIdentifier* name;
@property (nonatomic, strong)  id body;

@end
