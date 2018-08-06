//
//  MPWPropertyPath.h
//  ObjectiveSmalltalk
//
//  Created by Marcel Weiher on 8/6/18.
//

#import <Foundation/Foundation.h>

@interface MPWPropertyPath : NSObject

@property (nonatomic, strong) NSArray *pathComponents;
@property (readonly) NSString *name;

@end
