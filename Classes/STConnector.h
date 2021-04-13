//
//  STConnector.h
//  Arch-S
//
//  Created by Marcel Weiher on 09/02/2006.
//  Copyright 2006 Marcel Weiher. All rights reserved.
//

#import <ObjectiveSmalltalk/MPWExpression.h>

@class STMessagePortDescriptor;

@interface STConnector : NSObject {
}

@property (nonatomic,strong) STMessagePortDescriptor *source,*target;

-(BOOL)connect;
-(BOOL)isCompatible;


@end
