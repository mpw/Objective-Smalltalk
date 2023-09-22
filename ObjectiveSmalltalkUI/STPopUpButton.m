//
//  STPopUpButton.m
//  ObjectiveSmalltalkUI
//
//  Created by Marcel Weiher on 22.09.23.
//

#import "STPopUpButton.h"

@implementation STPopUpButton



-(BOOL)matchesRef:(id <MPWReferencing>)ref
{
    return YES;
}

-(void)modelDidChange:(NSNotification*)notification
{
    [self updateFromRef];
}

-(void)updateFromRef
{
    if ( self.ref && !self.inProcessing) {
        self.objectValue = self.ref.value;
    }
    if ( self.enabledRef && !self.inProcessing) {
        self.enabled = [self.enabledRef.value boolValue];
    }
}

-(void)updateToRef
{
    if (self.ref) {
        self.ref.value = self.objectValue;
    }
}

-(void)setBinding:(MPWBinding*)newBinding
{
    self.ref = newBinding;
    self.target = self;
    self.action = @selector(updateToRef);
}


@end
