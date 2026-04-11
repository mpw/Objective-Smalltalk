//
//  STSymbolCounter.h
//  ObjSTNative
//
//  Created by Marcel Weiher on 11.04.26.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface STSymbolCounter : NSObject

@property (nonatomic, strong ) NSString *template;

+(instancetype)counterWithTemplate:(NSString*)template;
-(NSString*)nextObject;

@end

NS_ASSUME_NONNULL_END
