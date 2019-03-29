//
//  MPWProgramTextView.m
//  SketchView
//
//  Created by Marcel Weiher on 9/15/15.
//  Copyright © 2015 Marcel Weiher. All rights reserved.
//

#import "MPWProgramTextView.h"
#import "MPWStCompiler.h"

@interface MPWProgramTextView ()

@property (nonatomic, strong) NSSliderTouchBarItem*  sliderTouchBarItem;

@end



@implementation MPWProgramTextView
{
    BOOL isDraggingNumber;
    NSPoint numberDraggingStartingPoint;
}

- (void)drawRect:(NSRect)dirtyRect {
//    NSLog(@"-[%@ %@]",[self className],NSStringFromSelector(_cmd));
    [super drawRect:dirtyRect];
    
    // Drawing code here.
}

-(void)setTextColor:(NSColor *)textColor
{
    NSLog(@"setTextColor: %@",textColor);
//    [super setTextColor:textColor];
}

-(void)changeColor:(nullable id)sender
{
    NSColor *c=[sender color];
    float r,g,b;
    NSRange oldSelected=[self selectedRange];
    r=[c redComponent];
    g=[c greenComponent];
    b=[c blueComponent];
    
    NSString *colorString=[NSString stringWithFormat:@"#%x%x%x",(int)(r*255),(int)(g*255),(int)(b*255)];
    [self insertText:colorString];
    [self setSelectedRange:NSMakeRange(oldSelected.location, [colorString length])];
}


- (void)setTextColor:(NSColor *)color
               range:(NSRange)range
{
    NSLog(@"textColor: %@ range: %@",color,NSStringFromRange(range));
}

- (NSString*)selectedText
{
    NSString *selected=nil;
    @try {
        selected=[[self string] substringWithRange:self.selectedRange];
    } @catch (NSException *exception) {
    } @finally {
    }
    return selected;
}

-(BOOL)isSelectedTextNumeric
{
    NSString *selected=[self selectedText];
    return [selected length] > 0 && ([selected isEqual:@"0"] || [selected doubleValue] != 0 );
}

-(void)mouseDown:(NSEvent *)theEvent
{
    if ( [self isSelectedTextNumeric] && ([theEvent modifierFlags] & NSAlternateKeyMask)) {
        isDraggingNumber=YES;
        numberDraggingStartingPoint=[theEvent locationInWindow];
        NSLog(@"start number dragging, start value = %d",[[self selectedText] intValue]);
    } else {
        [super mouseDown:theEvent];
    }
}



-(void)D:(NSEvent *)theEvent
{
    if (  isDraggingNumber ) {
        double deltaX = [theEvent locationInWindow].x - numberDraggingStartingPoint.x;
        int currentValue = [[self selectedText] intValue];
        int increment = 1;
        NSLog(@"in number dragging, current value = %d",currentValue);
        if ( deltaX > 0 ) {
            currentValue+=increment;
        } else {
            currentValue-=increment;
        }
        NSLog(@"new value=%d",currentValue);
        NSRange selectedRange=[self selectedRange];
        [self replaceCharactersInRange:selectedRange withString:[NSString stringWithFormat:@"%d",currentValue]];
        [self setSelectedRange:selectedRange];
        [self.delegate textDidChange:self];
        numberDraggingStartingPoint=[theEvent locationInWindow];
    } else {
        [super mouseDragged:theEvent];
    }
}

#define RETURN_CHAR    0x0D
#define BACKSPACE_CHAR 0x7F  // Note SHIFT + BACKSPACE gives 0x08

- (void)keyDown:(NSEvent *)theEvent  // Called by the AppKit when the user press a key.
{
    //NSLog(@"key = %@",[theEvent characters]);
    //NSLog(@"char0 = %d", (int)[[theEvent characters] characterAtIndex:0]);
    //NSLog(@"modifierFlags = %x",[theEvent modifierFlags]);
    
    if ([theEvent type] != NSKeyDown)
    {
        [super keyDown:theEvent];
        return;
    }
    
    if ([[theEvent characters] length] == 0) // this is the case in Jaguar for accents
    {
        [super keyDown:theEvent];
        return;
    }
    
    //unichar theCharacter = [[theEvent charactersIgnoringModifiers] characterAtIndex:0];
    unichar theCharacter = [[theEvent characters] characterAtIndex:0];
    
    NSUInteger theModifierFlags = [theEvent modifierFlags];
    
//    // Is the current insertion point valid ?
//    if ([self selectedRange].location < start
//        && !(theModifierFlags & NSShiftKeyMask
//             && (   theCharacter == NSLeftArrowFunctionKey
//                 || theCharacter == NSRightArrowFunctionKey
//                 || theCharacter == NSUpArrowFunctionKey
//                 || theCharacter == NSDownArrowFunctionKey)))
//    {
//        /*    if ([self selectedRange].location < (start - [prompt length]))
//         [self moveToEndOfDocument:self];
//         else
//         [self setSelectedRange:NSMakeRange(start,0)];*/
//        
//        if ([self selectedRange].location < start)
//            [self setSelectedRange:NSMakeRange(start,0)];
//        
//        [self scrollRangeToVisible:[self selectedRange]];
//    }
    
    if (theModifierFlags & NSControlKeyMask)
    {
        switch (theCharacter)
        {
            case '/':
                [self jumpToNextPlaceHolder];
                break;
            case RETURN_CHAR:
                [self insertNewlineIgnoringFieldEditor:self];
                break;
//            case BACKSPACE_CHAR:
//                [self setSelectedRange:NSMakeRange(start,[[self string] length])];
//                [self delete:self];
//                break;
//            case NSUpArrowFunctionKey:
//                [self replaceCurrentCommandWith:[[history goToPrevious] getStr]];
//                break;
//            case NSDownArrowFunctionKey:
//                [self replaceCurrentCommandWith:[[history goToNext] getStr]];
//                break;
            default:
                [super keyDown:theEvent];
                break;
        }
    }
    else
    {
        switch (theCharacter)
        {
            case 9:
                [self complete:self];
                break;
            case NSF7FunctionKey:
                [self switchParserMode:self];
                break;
            case NSF8FunctionKey:
                [self parenthesizeCommand:self];
                break;      
            default:
                [super keyDown:theEvent];
                break;
        }
    }
}

-(void)jumpToNextPlaceHolder
{
    const unichar placeHolderCharacter = 8226;
    NSString *placeHolderString = [NSString stringWithCharacters:&placeHolderCharacter length:1];
    NSString *text = [self string];
    NSRange selectedRange = [self selectedRange];
    NSRange nextPlaceHolderRange;
    
    if ([[text substringWithRange:selectedRange] isEqualToString:placeHolderString])
        nextPlaceHolderRange = [text rangeOfString:placeHolderString options:NSLiteralSearch range:NSMakeRange(selectedRange.location + 1, [text length] - (selectedRange.location + 1))];
    else
        nextPlaceHolderRange = [text rangeOfString:placeHolderString options:NSLiteralSearch range:NSMakeRange(selectedRange.location, [text length] - selectedRange.location)];
    
    if (nextPlaceHolderRange.location == NSNotFound) nextPlaceHolderRange = [text rangeOfString:placeHolderString options:NSLiteralSearch range:NSMakeRange(0, selectedRange.location)];
    if (nextPlaceHolderRange.location == NSNotFound)
    {
        if (![[text substringWithRange:selectedRange] isEqualToString:placeHolderString]) NSBeep();
    }
    else                                             [self setSelectedRange:nextPlaceHolderRange];
}




- (void)insertCompletion:(NSString *)word forPartialWordRange:(NSRange)charRange movement:(NSInteger)movement isFinal:(BOOL)flag
{
    // NSLog(@"word = %@, movement = %@, isFlinal = %@", word, [NSNumber numberWithInteger:movement], flag ? @"YES" : @"NO");
    
    const unichar placeHolderCharacter = 8226;
    NSString *placeHolderString = [NSString stringWithCharacters:&placeHolderCharacter length:1];
    NSMutableString *stringToDisplay = [[word mutableCopy] autorelease];
    NSUInteger replacedCount = [stringToDisplay replaceOccurrencesOfString:@":" withString:[NSString stringWithFormat:@":%@ ", placeHolderString] options:NSLiteralSearch range:NSMakeRange(0, [stringToDisplay length])];
    
    if (flag && movement != NSCancelTextMovement && replacedCount > 1)
    {
        [super insertCompletion:stringToDisplay forPartialWordRange:charRange movement:movement isFinal:flag];
        NSString *text = [self string];
        [self setSelectedRange:[text rangeOfString:placeHolderString options:NSLiteralSearch range:NSMakeRange(charRange.location, [stringToDisplay length])]];
    }
    else {
        [super insertCompletion:word forPartialWordRange:charRange movement:movement isFinal:flag];
    }
}



-(NSString *)currentCommandLine
{
    NSRange currentSelection=[self rangeForUserCompletion];
    NSString *s=[self string];
    int parenCount=0;
    BOOL done=NO;
    while ( currentSelection.location > 0 && !done) {
        unichar ch =[s characterAtIndex:currentSelection.location-1];
        switch (ch) {
            case 10:
            case '.':
                done=YES;
                break;
            case ')':
                parenCount++;
                break;
            case '(':
                parenCount--;
                if ( parenCount < 0) {
                    done=YES;
                }
                break;
            default:
                 break;
        }
        if (!done) {
            currentSelection.location--;
            currentSelection.length++;
        }
    }
    return [[self string] substringWithRange:currentSelection];
}

-(NSString *)insertPlaceHoldersIntoCompletion:(NSString *)completion
{
    const unichar placeHolderCharacter = 8226;
    NSString *newSeparator=[NSString stringWithFormat:@":%C ",placeHolderCharacter];
    return [[completion componentsSeparatedByString:@":"] componentsJoinedByString:newSeparator];
}

- (NSArray *)completionsForPartialWordRange:(NSRange)charRange indexOfSelectedItem:(NSInteger *)index
{
    NSString *completionFor=[[self string] substringWithRange:charRange];
    NSString *selectedText=[self selectedText];
    NSRange selectedRange=[self selectedRange];
    NSLog(@"SelectedText: %@",selectedText);
    NSLog(@"range: %@",[self selectedRanges]);
    NSString *currentCommand = [self currentCommandLine];
    NSArray *completions = nil;
    @try {
        completions = [self.delegate completionsForString:currentCommand];
    } @catch (NSException *e) {
        NSLog(@"error trying to complete: %@",e);
    }
    
    
    if ( [completions count]==1 && [[completions firstObject] isEqualToString:completionFor]) {
        [self insertText:@" "];
        completions=nil;
    }
    
    if ( [completions count]==1 && [[completions firstObject] isEqualToString:@" "]) {
        [self insertText:@" "];
        completions=nil;
    }
    
    NSString *common=[completions firstObject];
    for ( NSString *s in completions) {
        common=[common commonPrefixWithString:s options:NSLiteralSearch];
    }
    if ( [common length] > charRange.length) {
        NSString *commonSelected=selectedText;
        NSLog(@"common: '%@'  commonSelected: '%@' completionFor: %@",common,commonSelected,completionFor);
        if ( [common  isEqualToString:[completionFor stringByAppendingString:commonSelected]] ) {
            self.selectedRange = NSMakeRange( selectedRange.location + selectedRange.length , 0);
        } else {
            [self insertCompletion:common forPartialWordRange:charRange movement:0 isFinal:YES];
        }

//        [self insertText:[common substringFromIndex:charRange.length]];
        return nil;
    }
    
    return [completions sortedArrayUsingComparator:^NSComparisonResult(NSString*   s1, NSString *s2) {
        return [s1 length] - [s2 length];
    }];
    
    
}


-(void)mouseUp:(NSEvent *)theEvent
{
    if (  isDraggingNumber ) {
        isDraggingNumber=NO;
    }
    [super mouseUp:theEvent];
}


//---- Touch Bar

static BOOL fromTouchBar=NO;

-(void)textViewDidChangeSelection:(NSNotification *)notification
{
    if ( [self isSelectedTextNumeric] && !fromTouchBar) {
        [self setTouchBarRangeFromValue:[[self selectedText] floatValue]];
    }
}

- (IBAction)useSliderAccessoryAction:(id)sender
{
    NSImage *minSliderImage = nil;
    NSImage *maxSliderImage = nil;
    
    if (((NSButton *)sender).state == NSOnState)
    {
        minSliderImage = [NSImage imageNamed:@"Red"];
        maxSliderImage = [NSImage imageNamed:@"Green"];
    }
    
    NSSliderAccessory *minSliderAccessory = [NSSliderAccessory accessoryWithImage:minSliderImage];
    self.sliderTouchBarItem.minimumValueAccessory = minSliderAccessory;
    
    NSSliderAccessory *maxSliderAccessory = [NSSliderAccessory accessoryWithImage:maxSliderImage];
    self.sliderTouchBarItem.maximumValueAccessory = maxSliderAccessory;
}

static NSString *SliderCustomizationIdentifier=@"com.metaobject.CodeDraw.SliderCustom";
static NSString *SliderItemIdentifier=@"com.metaobject.CodeDraw.Slider";

- (NSTouchBar *)makeTouchBar
{
    NSTouchBar *bar = [[NSTouchBar alloc] init];
    bar.delegate = self;
    
    bar.customizationIdentifier = SliderCustomizationIdentifier;
    
    // Set the default ordering of items.
    bar.defaultItemIdentifiers =
    @[SliderItemIdentifier, NSTouchBarItemIdentifierOtherItemsProxy];
    
    bar.customizationAllowedItemIdentifiers = @[SliderItemIdentifier];
    
    return bar;
}

-(NSRange)guessRangeFromValue:(float)value
{
    if ( value < 0 ) {
        NSRange r=[self guessRangeFromValue:-value];
        return NSMakeRange( -r.location, r.length*2);
    }
    int maxValue=1;
    for (int i=1;i<5;i++) {
        if ( value < maxValue ) {
            break;
        }
        maxValue*=10;
    }
    return NSMakeRange(0, maxValue);
}

-(void)setTouchBarRangeFromValue:(float)value
{
    NSRange r=[self guessRangeFromValue:value];
    NSLog(@"touch bar from value %g, range: (%d,%d)",value,r.location,r.length);
    self.sliderTouchBarItem.slider.minValue = r.location;
    self.sliderTouchBarItem.slider.maxValue = r.length;
    self.sliderTouchBarItem.slider.doubleValue = value;
}

- (nullable NSTouchBarItem *)touchBar:(NSTouchBar *)touchBar makeItemForIdentifier:(NSTouchBarItemIdentifier)identifier
{
    if ([identifier isEqualToString:SliderItemIdentifier])
    {
        _sliderTouchBarItem = [[NSSliderTouchBarItem alloc] initWithIdentifier:SliderItemIdentifier];
        
        self.sliderTouchBarItem.slider.minValue = 0.0f;
        self.sliderTouchBarItem.slider.maxValue = 100.0f;
        self.sliderTouchBarItem.slider.doubleValue = 50.0f;
        self.sliderTouchBarItem.slider.continuous = YES;
        self.sliderTouchBarItem.target = self;
        self.sliderTouchBarItem.action = @selector(touchBarSliderChanged:);
        self.sliderTouchBarItem.label = NSLocalizedString(@"Slider", @"");
        self.sliderTouchBarItem.customizationLabel = NSLocalizedString(@"Slider", @"");
        
        // Keep track of the slider value for next time, also helps us sync the slider item
        // with the slider in this view controller.
        //
        [self.sliderTouchBarItem.slider bind:NSValueBinding
                                    toObject:[NSUserDefaultsController sharedUserDefaultsController]
                                 withKeyPath:@"values.slider"
                                     options:nil];
        
        return self.sliderTouchBarItem;
    }
    
    return nil;
}

- (void)touchBarSliderChanged:(NSSliderTouchBarItem *)sender
{
    fromTouchBar=YES;
    double currentValue=[sender.slider doubleValue];
    if ( self.sliderTouchBarItem.slider.maxValue > 10 ) {
        currentValue=round(currentValue);
    } else if ( self.sliderTouchBarItem.slider.maxValue > 1) {
        currentValue=round(currentValue*10)/10;
    } else if ( self.sliderTouchBarItem.slider.maxValue > 0) {
        currentValue=round(currentValue*100)/100;
    }
    if ( [self isSelectedTextNumeric]) {
        NSRange selectedRange=[self selectedRange];
        NSString *newString = [NSString stringWithFormat:@"%g",currentValue];
        [self replaceCharactersInRange:selectedRange withString:newString];
        [self setSelectedRange:NSMakeRange(selectedRange.location, newString.length)];
        [self.delegate textDidChange:self];
    }
    fromTouchBar=NO;
}

-(IBAction)doIt:sender
{
    [self.compiler evaluateScriptString:[self selectedText]];
}
-(IBAction)printIt:sender;
{
    id result = [self.compiler evaluateScriptString:[self selectedText]];
    NSString *resultText=[result stringValue];
    NSRange currentSelection=[self selectedRange];
    [self setSelectedRange:NSMakeRange( currentSelection.location+currentSelection.length,0)];
    currentSelection=[self selectedRange];
    if ( resultText.length ) {
        [self insertText:resultText];
        [self setSelectedRange:NSMakeRange( currentSelection.location, resultText.length)];
    }
}


@end
