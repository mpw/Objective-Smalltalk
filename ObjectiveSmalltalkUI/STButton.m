//
//  STButton.m
//  ObjectiveSmalltalkUI
//
//  Created by Marcel Weiher on 04.09.23.
//

#import "STButton.h"

@implementation STButton

-(instancetype)initWithFrame:(NSRect)frameRect
{
    self=[super initWithFrame:frameRect];
    [self installProtocolNotifications];
    return self;
}



-(void)modelDidChange:(NSNotification*)notification
{
    [self updateFromRef];
}

-(void)validationDidChange:(NSNotification*)notification
{
    [self updateFromRef];
}

-(void)updateFromRef
{
//    NSLog(@"updating button %@ with ref: %@ value: %@",self,self.enabledRef,[self.enabledRef value]);
    if ( self.enabledRef ) {
        self.enabled = [self.enabledRef.value boolValue];
    }
}


@end
