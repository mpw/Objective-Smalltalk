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

-(instancetype)initWithDictionary:aDict
{
    self=[super initWithDictionary:aDict];
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

-(void)selectionDidChange:(NSNotification*)notification
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
//    NSLog(@"updateFromRef, self= %p ref=%p/%@",self,self.ref,self.ref);
//    NSLog(@"updateFromRef, value=%p/%@",self.ref.value,self.ref.value);
//    NSLog(@"updateFromRef, objectValue=%p/%@",self.objectValue,self.objectValue);
//    NSLog(@"updateFromRef after niling, objectValue=%p/%@",self.objectValue,self.objectValue);
    if ( self.ref && !self.inProcessing) {
        self.objectValue = [self.ref.value stringValue];
    }
    if ( self.enabledRef ) {
        self.enabled = [self.enabledRef.value boolValue];
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
        @try {
            self.inProcessing=YES;
            NSLog(@"update to ref %@ -> %@",self.ref,self.objectValue);
            self.ref.value = self.objectValue;
            NSLog(@"did update to ref %@ -> %@",self.ref.value,self.objectValue);
        } @finally {
            self.inProcessing=NO;
        }
   }
}

-(void)setBinding:(MPWReference*)newBinding
{
    self.ref = newBinding;
    self.target = self;
    self.action = @selector(updateToRef);
}



@end
