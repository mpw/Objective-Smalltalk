//
//  MPWPropertyPathComponent.h
//  ObjectiveSmalltalk
//
//  Created by Marcel Weiher on 8/6/18.
//

#import <Foundation/Foundation.h>

@interface MPWPropertyPathComponent : NSObject

@property (nonatomic, strong) NSString *name;
@property (nonatomic, strong) NSString *parameter;
@property (nonatomic, assign) BOOL isWildcard;

@property (readonly) NSString *pathName;


+(instancetype)componentWithString:(NSString*)aString;
-(instancetype)initWithString:(NSString*)aString;


@end
