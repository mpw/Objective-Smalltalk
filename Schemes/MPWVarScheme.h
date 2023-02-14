//
//  MPWVarScheme.h
//  Arch-S
//
//  Created by Marcel Weiher on 25.12.09.
//  Copyright 2009 Marcel Weiher. All rights reserved.
//

#import <ObjectiveSmalltalk/MPWSelfContainedBindingsScheme.h>

@class STEvaluator;

@interface MPWVarScheme : MPWSelfContainedBindingsScheme {
}

@property (nonatomic, strong ) STEvaluator *context;

@end
