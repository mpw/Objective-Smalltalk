//
//  SailsControl.h
//  Sails
//
//  Created by Marcel Weiher on 03.05.26.
//

#import <Foundation/Foundation.h>

// NS_ASSUME_NONNULL_BEGIN

@interface SailsControl : NSObject

-(int)main:(int)argc argv:(const char**)argv stsh:stsh;
-(int)main:(NSArray*)args stsh:stsh;

@end

// NS_ASSUME_NONNULL_END
