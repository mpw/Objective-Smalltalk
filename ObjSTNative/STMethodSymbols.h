//
//  STMethodSymbols.h
//  ObjSTNative
//
//  Created by Marcel Weiher on 12.07.23.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface STMethodSymbols : NSObject


@property (nonatomic, strong ) NSMutableArray *symbolNames;
@property (nonatomic, strong ) NSMutableArray *methodNames;
@property (nonatomic, strong ) NSMutableArray *methodTypes;


@end

NS_ASSUME_NONNULL_END
