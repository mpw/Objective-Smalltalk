//
//  STTextField.m
//  ObjectiveSmalltalkUI
//
//  Created by Marcel Weiher on 27.02.21.
//

#import "STTextField.h"

@implementation STTextField

-(instancetype)initWithFrame:(NSRect)frameRect
{
    self=[super initWithFrame:frameRect];
    [self installProtocolNotifications];
    return self;
}

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
}

-(void)setText:(NSString*)text{
    self.stringValue=text;
}

-(NSString*)text {
    return self.stringValue;
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
