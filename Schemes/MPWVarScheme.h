//
//  MPWVarScheme.h
//  MPWTalk
//
//  Created by Marcel Weiher on 25.12.09.
//  Copyright 2009 Marcel Weiher. All rights reserved.
//

#import <ObjectiveSmalltalk/MPWSelfContainedBindingsScheme.h>

@class MPWEvaluator;

@interface MPWVarScheme : MPWSelfContainedBindingsScheme {
}

@property (nonatomic, strong ) MPWEvaluator *context;

@end
