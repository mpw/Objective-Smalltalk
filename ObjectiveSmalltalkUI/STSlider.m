//
//  STSlider.m
//  ObjectiveSmalltalkUI
//
//  Created by Marcel Weiher on 25.09.23.
//

#import "STSlider.h"

@implementation STSlider

-(instancetype)initWithFrame:(NSRect)frameRect
{
    self=[super initWithFrame:frameRect];
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
    //    NSLog(@"text field validation changed: %@ from %@",notification,self.enabledRef);
    if ( self.enabledRef ) {
        self.enabled = [self.enabledRef.value boolValue];
        //        NSLog(@"enabled now: %d",self.enabled);
    }
}

-(void)updateFromRef
{
    if ( self.ref ) {
        self.doubleValue = [self.ref.value doubleValue];
    }
    if ( self.enabledRef ) {
        self.enabled = [self.enabledRef.value boolValue];
    }
}


-(void)updateToRef
{
    if (self.ref) {
        self.ref.value = @(self.doubleValue);
    }
}

-(void)setBinding:(MPWReference*)newBinding
{
    self.ref = newBinding;
    self.target = self;
    self.action = @selector(updateToRef);
}


@end
