//
//  STUIKitAdditions.m
//  ObjectiveSmalltalkTouchUI
//
//  Created by Marcel Weiher on 28.02.21.
//

#import <UIKit/UIKit.h>
#import <ObjectiveSmalltalk/STTargetActionSenderPort.h>
#import <ObjectiveSmalltalk/STMessagePortDescriptor.h>

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

-defaultInputPort
{
    return [[[STMessagePortDescriptor alloc] initWithTarget:self key:nil protocol:@protocol(Streaming) sends:NO] autorelease];
}

-(NSString *)stringValue
{
    return [[self objectValue] stringValue];
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


@implementation UISlider(setValue)

-(void)setObjectValue:anObject
{
    [self setValue:[anObject floatValue]
          animated:YES];
}

-objectValue
{
    return @(self.value);
}

@end

@interface UILabel(setValue) <Streaming>
@end

@implementation UILabel(setValue)

-(void)setObjectValue:anObject
{
    [self setText:[anObject stringValue]];
}

-objectValue
{
    return self.text;
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

-defaultInputPort
{
    return [[[STMessagePortDescriptor alloc] initWithTarget:self key:nil protocol:@protocol(Streaming) sends:NO] autorelease];
}

@end

