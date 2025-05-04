//
//  MPWFrameworkScheme.h
//  ObjectiveSmalltalk
//
//  Created by Marcel Weiher on 4/15/14.
//
//

#import <ObjectiveSmalltalk/MPWScheme.h>

@interface MPWFrameworkScheme : MPWScheme

@end

@class MPWCFunction;

@interface NSBundle(SymbolLoading)

-(MPWCFunction*)functionNamed:(NSString*)fname;

@end
