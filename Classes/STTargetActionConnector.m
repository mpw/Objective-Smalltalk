//
//  STTargetActionConnector.m
//  ObjectiveSmalltalk
//
//  Created by Marcel Weiher on 25.02.21.
//

#import "STTargetActionConnector.h"

@implementation STTargetActionConnector

-(instancetype)initWithSelector:(SEL)newSelector
{
    self=[super init];
    self.message=newSelector;
    return self;
}

@end
