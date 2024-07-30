//
//  STProgressIndicator.m
//  ObjectiveSmalltalkUI
//
//  Created by Marcel Weiher on 25.09.23.
//

#import "STProgressIndicator.h"

@implementation STProgressIndicator

-(instancetype)initWithFrame:(NSRect)frameRect
{
    self=[super initWithFrame:frameRect];
    self.indeterminate=false;
    [self installProtocolNotifications];
    return self;
}

-(BOOL)matchesRef:(id <MPWIdentifying>)ref
{
    return YES;
}

-(void)modelDidChange:(NSNotification*)notification
{
    [self updateFromRef];
}

-(void)validationDidChange:(NSNotification*)notification
{
    if ( self.enabledRef ) {
//        self.enabled = [self.enabledRef.value boolValue];
    }
}

-(void)updateFromRef
{
    if ( self.ref ) {
        self.doubleValue = [self.ref.value doubleValue];
    }
    if ( self.minRef ) {
        self.minValue = [self.minRef.value doubleValue];
    }
    if ( self.maxRef ) {
        self.maxValue = [self.maxRef.value doubleValue];
    }
    if ( self.enabledRef ) {
//        self.enabled = [self.enabledRef.value boolValue];
    }
}



@end
