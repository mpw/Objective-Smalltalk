//
//  MPWELFSmybolTable.h
//  ObjSTNative
//
//  Created by Marcel Weiher on 04.05.24.
//

#import "MPWELFSection.h"

NS_ASSUME_NONNULL_BEGIN

@interface MPWELFSmybolTable : MPWELFSection

-(NSString*)symbolNameAtIndex:(int)anIndex;



@end

NS_ASSUME_NONNULL_END
