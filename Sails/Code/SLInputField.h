//
//  SLInputField.h
//  Sails
//
//  Created by Marcel Weiher on 06.06.26.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface SLInputField : NSObject

@property (nonatomic, strong) NSString *type;
@property (nonatomic, strong) NSString *name;
@property (nonatomic, strong) id value;
@property (nonatomic, strong) NSString* htmx_put;
@property (nonatomic, strong) NSString* htmx_post;

@end

NS_ASSUME_NONNULL_END
