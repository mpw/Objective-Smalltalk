//
//  STUIAppKitAdditions.m
//  ObjectiveSmalltalkUI
//
//  Created by Marcel Weiher on 28.02.21.
//

#import <AppKit/AppKit.h>
#import <ObjectiveSmalltalk/ObjectiveSmalltalk.h>
#import "STTargetActionSenderPort.h"



@implementation NSTextField(debug)

-(void)dumpOn:(MPWByteStream*)aStream
{
    [aStream printFormat:@"<%s:%p: ",object_getClassName(self),self];
    [aStream printFormat:@"frame: %@ ",NSStringFromRect(self.frame)];
    [aStream printFormat:@"stringValue: %@ ",self.stringValue];
    [aStream printFormat:@"textColor: %@ ",self.textColor];
    [aStream printFormat:@"backGroundColor: %@ ",self.backgroundColor];
    [aStream printFormat:@"drawsBackground: %d ",self.drawsBackground];
    [aStream printFormat:@"isBordered: %d ",self.isBordered];
    [aStream printFormat:@"isSelectable: %d ",self.isSelectable];
    [aStream printFormat:@"isOpaque: %d",self.isOpaque];
    
    [aStream printFormat:@">\n"];
}



@end


@implementation NSControl(streaming)

-defaultInputPort
{
    return [[[STMessagePortDescriptor alloc] initWithTarget:self key:nil protocol:@protocol(Streaming) sends:NO] autorelease];
}


-(void)writeObject:anObject
{
    self.objectValue = anObject;
}

-(void)writeTarget:(NSControl*)source
{
    self.objectValue = [source objectValue];
}

-(void)appendBytes:(const void*)bytes length:(long)len
{
    self.stringValue = [NSString stringWithCString:bytes length:len];
}

@end

@implementation NSGridView(sizeandviews)

+gridViewWithSize:(NSSize)size views:views {
    NSGridView *grid = [self gridViewWithViews:views];
    [grid setFrameSize:size];
    return grid;
}

@end


@implementation NSControl(ports)

-defaultOutputPort
{
    return [[[STTargetActionSenderPort alloc] initWithControl:self] autorelease];
}

-(void)setTarget:(id)target action:(SEL)action
{
    self.target=target;
    self.action=action;
}

@end

@interface TextFieldContinuity : NSObject

@end

@implementation TextFieldContinuity


+(void)controlTextDidChange:(NSNotification *)notification
{
    NSTextField *changedField = [notification object];
    if (changedField.isContinuous) {
        BOOL canProtect = [changedField respondsToSelector:@selector(setInProcessing:)];
        if ( canProtect) {
            [changedField setInProcessing:YES];
        }
        @try {
            [changedField.target performSelector:changedField.action withObject:changedField];
        } @catch ( id exception ) {
            NSLog(@"%@:%@ exception delivering action %@ to target %@",[changedField className],changedField,NSStringFromSelector([changedField action]),[changedField target]);
        } @finally {
            if ( canProtect) {
                [changedField setInProcessing:YES];
            }
        }
    }
}



@end

@implementation NSTextField(continuous)


-(void)setContinuous:(BOOL)continuous
{
    [super setContinuous:continuous];
    if ( continuous) {
        self.delegate = (id)[TextFieldContinuity class];
    } else {
        if ( self.delegate == [TextFieldContinuity class]) {
            self.delegate=nil;
        }
    }
}

@end

@implementation NSStackView(view)

-(void)setViews:(NSArray<__kindof NSView *> * _Nonnull)views
{
    for (NSView *view in views) {
        [self addArrangedSubview:view];
    }
}

@end
