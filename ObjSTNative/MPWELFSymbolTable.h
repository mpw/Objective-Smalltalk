//
//  MPWELFSymbolTable.h
//  ObjSTNative
//
//  Created by Marcel Weiher on 04.05.24.
//

#import "MPWELFSection.h"

NS_ASSUME_NONNULL_BEGIN

@interface MPWELFSymbolTable : MPWELFSection

-(NSString*)symbolNameAtIndex:(int)anIndex;
-(int)symbolInfoAtIndex:(int)anIndex;
-(int)symbolTypeAtIndex:(int)anIndex;
-(long)symbolValueAtIndex:(int)anIndex;



@end

NS_ASSUME_NONNULL_END
