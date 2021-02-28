//
//  STUIKitAdditions.m
//  ObjectiveSmalltalkTouchUI
//
//  Created by Marcel Weiher on 28.02.21.
//

#import <UIKit/UIKit.h>
#import <ObjectiveSmalltalk/STTargetActionSenderPort.h>

@implementation UIControl(targetAction)

-objectValue  { return nil; }
-(void)setObjectValue:newValue {}

-(void)setTarget:target action:(SEL)action
{
    [self addTarget:target action:action forControlEvents:UIControlEventValueChanged];
}

-defaultOutputPort
{
    return [[[STTargetActionSenderPort alloc] initWithControl:self] autorelease];
}

-(void)writeObject:anObject
{
    self.objectValue = anObject;
}

-(void)writeTarget:(UIControl*)source
{
    self.objectValue = [source objectValue];
}

@end

@implementation UIButton(targetAction)

-(void)setTarget:target action:(SEL)action
{
    [self addTarget:target action:action forControlEvents:UIControlEventPrimaryActionTriggered];
}

@end

@implementation UITextField(targetAction)

-(void)setObjectValue:aValue
{
    self.text = [aValue stringValue];
}

-(id)objectValue
{
    return self.text;
}

-(void)appendBytes:(const void*)bytes length:(long)len
{
    [self setObjectValue: [NSString stringWithCString:bytes length:len]];
}

-(void)setTarget:target action:(SEL)action
{
    [self addTarget:target action:action forControlEvents:UIControlEventEditingChanged];
}



@end
