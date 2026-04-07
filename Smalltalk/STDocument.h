//
//  Document.h
//  Smalltalk
//
//  Created by Marcel Weiher on 31.03.19.
//

#import <Cocoa/Cocoa.h>

@class STBundle;

@interface STDocument : NSDocument <NSToolbarDelegate>

@property (nonatomic, strong ) STBundle *bundle;

@end

