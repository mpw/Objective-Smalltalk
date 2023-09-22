//
//  ModelDidChangeNotification.h
//  ObjectiveSmalltalkUI
//
//  Created by Marcel Weiher on 09.03.21.
//

#ifndef ModelDidChangeNotification_h
#define ModelDidChangeNotification_h

#import <MPWFoundation/MPWFoundation.h>

@protocol ModelDidChange<MPWNotificationProtocol>

-(void)modelDidChange:(NSNotification*)notification;

@end

@protocol ValidationDidChange<MPWNotificationProtocol>

-(void)validationDidChange:(NSNotification*)notification;

@end

#endif /* ModelDidChangeNotification_h */
