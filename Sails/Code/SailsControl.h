//
//  SailsControl.h
//  Sails
//
//  Created by Marcel Weiher on 03.05.26.
//

#import <Foundation/Foundation.h>

// NS_ASSUME_NONNULL_BEGIN
@class STCompiler;

@interface SailsControl : NSObject

-(int)main:(int)argc argv:(const char**)argv;
-(int)main:(NSArray*)args;

@property (nonatomic,strong) STCompiler* compiler;
@property (nonatomic,assign) Class httpServerClass;

@end

// NS_ASSUME_NONNULL_END
