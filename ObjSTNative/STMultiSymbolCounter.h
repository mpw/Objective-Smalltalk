//
//  STMultiSymbolCounter.h
//  ObjSTNative
//
//  Created by Marcel Weiher on 14.04.26.
//

#import <Foundation/Foundation.h>

@class STSymbolCounter;

NS_ASSUME_NONNULL_BEGIN

@interface STMultiSymbolCounter : NSObject

@property (nonatomic, strong) NSMutableDictionary <NSString*, STSymbolCounter*> * counters;

-(NSString*)nextSymbolForTemplate:(NSString*)string;

@end

NS_ASSUME_NONNULL_END
