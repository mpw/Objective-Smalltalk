//
//  ViewBuilderPreviewNotification.h
//  ViewBuilder
//
//  Created by Marcel Weiher on 08.03.21.
//  Copyright © 2021 Marcel Weiher. All rights reserved.
//
//#import <MPWFoundation/MPWFoundation.h>

@protocol ViewBuilderAppKitPreviewNotification<MPWDistributedNotificationProtocol>

-(void)evaluateNewCode:(NSNotification*)notification;

@end

@protocol ViewBuilderUIKitPreviewNotification<MPWDistributedNotificationProtocol>

-(void)evaluateNewCode:(NSNotification*)notification;

@end

