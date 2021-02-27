//
//  STTextField.m
//  ObjectiveSmalltalkUI
//
//  Created by Marcel Weiher on 27.02.21.
//

#import "STTextField.h"

@implementation STTextField

-(void)setNeedsDisplay
{
    NSLog(@"setNeedsDisplay");
    [super setNeedsDisplay];
}

-(void)setNeedsDisplayInRect:(NSRect)invalidRect
{
    NSLog(@"setNeedsDisplayInRect: %@",NSStringFromRect(invalidRect));
    [super setNeedsDisplayInRect:invalidRect];
}

-(void)setNeedsDisplay:(BOOL)needsDisplay
{
    NSLog(@"setNeedsDisplay: %d",needsDisplay);
    [super setNeedsDisplay:needsDisplay];
}

-(void)setStringValue:(NSString *)stringValue
{
    NSLog(@"old: '%@' new: '%@' equal: %d",self.stringValue,stringValue,[self.stringValue isEqual:stringValue]);
    [super setStringValue:stringValue];
    NSLog(@"did set");
}

@end
