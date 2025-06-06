/* ShellView.m Copyright (c) 1998-2009 Philippe Mougin.     */
/* This software is open source. See the license.           */  
/* This file includes contributions from Stephen C. Gilardi */

#import "ShellView.h"
#import "FSCommandHistory.h"
#import <MPWFoundation/MPWFoundation.h>
#import "STCompiler.h"
#import "MPWExpression+autocomplete.h"
#import "MPWShellPrinter.h"


#define RETURN_CHAR    0x0D
#define BACKSPACE_CHAR 0x7F  // Note SHIFT + BACKSPACE gives 0x08
  
static NSDictionary *errorAttributes; // a dictionary of attributes that defines how an error in a command is shown. 
static BOOL useMaxSize;

@implementation ShellView 

/////////////////////////////// PRIVATE ////////////////////////////

-(void)insertTextAtCursor:someText
{
    [self insertText:someText];
}

+ (void) setUseMaxSize:(BOOL)shouldUseMaxSize
{
  useMaxSize = shouldUseMaxSize;
}

- (void) replaceCurrentCommandWith:(NSString *)newCommand   // This method is used when the user browse into the command history
{
  [self setSelectedRange:NSMakeRange(start,[[self string] length])];
  [self insertTextAtCursor:newCommand];
  [self moveToEndOfDocument:self];
  [self scrollRangeToVisible:[self selectedRange]];
  lineEdited = NO; 
}

/////////////////////////////// PUBLIC ////////////////////////////

+ (void)initialize  
{
    static BOOL tooLate = NO;
    if (!tooLate)
    {
        tooLate = YES;
        errorAttributes = [[NSDictionary alloc] initWithObjectsAndKeys: [NSColor whiteColor],NSForegroundColorAttributeName, [NSColor blackColor], NSBackgroundColorAttributeName, nil];
        useMaxSize = YES;
    }
}

//- (BOOL)acceptsFirstResponder {/*NSLog(@"ShellView acceptsFirstResponder");*/ return YES;}

//- (BOOL)becomeFirstResponder {/*NSLog(@"ShellView becomeFirstResponder");*/  return YES;}

//- (BOOL)acceptsFirstMouse:(NSEvent *)theEvent {/*NSLog(@"ShellView acceptsFirstMouse:");*/ return YES;}

-(void)awakeFromNib
{
    [super awakeFromNib];
    [self setRichText:NO];
}

- (id)commandHandler { return commandHandler;}

- (NSArray *)completionsForPartialWordRange:(NSRange)charRange indexOfSelectedItem:(NSInteger *)index
{
    NSString *completionFor=[[self string] substringWithRange:charRange];
    

    
    NSString *currentCommand = [self currentCommandLine];
    NSArray *completions = [commandHandler completionsForString:currentCommand];

    
    if ( [completions count]==1 && [[completions firstObject] isEqualToString:completionFor]) {
        [self insertTextAtCursor:@" "];
        completions=nil;
    }
    
    if ( [completions count]==1 && [[completions firstObject] isEqualToString:@" "]) {
        [self insertTextAtCursor:@" "];
        completions=nil;
    }
    
    NSString *common=[completions firstObject];
    for ( NSString *s in completions) {
        common=[common commonPrefixWithString:s options:NSLiteralSearch];
    }
    if ( [common length] > charRange.length) {
        [self insertTextAtCursor:[common substringFromIndex:charRange.length]];
        return nil;
    }
    
    return completions;
    

}

- (void) dealloc
{
    [prompt release];
    [history release];
    if (shouldRetainCommandHandler) {
        [commandHandler release];
    }
    [super dealloc];
}

- (id)initWithFrame:(NSRect)frameRect
{
    return [self initWithFrame:frameRect prompt:@"] " historySize:20000 commandHandler:nil];
}

- (NSUndoManager*)undoManager
{
    return  nil;
}

- (id)initWithFrame:(NSRect)frameRect prompt:(NSString *)thePrompt historySize:(NSInteger)theHistorySize commandHandler:(id)theCommandHandler
{
  if (self = [super initWithFrame:frameRect])
  {
    prompt             = [thePrompt retain];
    history            = [[FSCommandHistory alloc] initWithUIntSize:theHistorySize];
    parserMode         = NO_DECOMPOSE;
    commandHandler     = [theCommandHandler retain];
    lineEdited         = NO;
    last_command_start = 0;
    shouldRetainCommandHandler = YES;

    [self setUsesFindPanel:YES];
//    [self setFont:[NSFont userFixedPitchFontOfSize:-1]]; // -1 to get the default font size
    [self setSelectedRange:NSMakeRange([[self string] length],0)];
    [self insertTextAtCursor:prompt];
    start = [[self string] length];
    [self setDelegate:self];   // A ShellView is its own delegate! (see the section implementing delegate methods)
    maxSize = 900000;
    [self setAllowsUndo:YES];
      [self setSmartInsertDeleteEnabled:NO];
      [self setAutomaticTextReplacementEnabled:NO];
      [self setAutomaticSpellingCorrectionEnabled:NO];
     
      [self setAutomaticQuoteSubstitutionEnabled:NO];
 [self setRichText:NO];

      
    return self;
  }
  return nil;
}

- (void) notifyUser:(NSString *)notification
{
  NSString *command = [[self string] substringFromIndex:start];
  NSRange selectedRange = [self selectedRange];
  NSInteger delta = [prompt length] + [notification length] + 2;
  
  [self setSelectedRange:NSMakeRange(start,[[self string] length])];
  [self insertTextAtCursor:[NSString stringWithFormat:@"\n%@\n%@%@", notification, prompt, command]];
//  [self setFont:[NSFont boldSystemFontOfSize:[NSFont systemFontSize]] range:NSMakeRange(start, [notification length]+1)];
  start += delta;
  [self setSelectedRange:NSMakeRange(selectedRange.location+delta, selectedRange.length)]; 
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
  
  // Is the current insertion point valid ?
  if ([self selectedRange].location < start 
      && !(theModifierFlags & NSShiftKeyMask
           && (   theCharacter == NSLeftArrowFunctionKey 
               || theCharacter == NSRightArrowFunctionKey
               || theCharacter == NSUpArrowFunctionKey
               || theCharacter == NSDownArrowFunctionKey)))
  {
    /*    if ([self selectedRange].location < (start - [prompt length]))
    [self moveToEndOfDocument:self];
    else
    [self setSelectedRange:NSMakeRange(start,0)];*/
    
    if ([self selectedRange].location < start)
      [self setSelectedRange:NSMakeRange(start,0)];      
    
    [self scrollRangeToVisible:[self selectedRange]];  
  }
  
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
      case BACKSPACE_CHAR:
        [self setSelectedRange:NSMakeRange(start,[[self string] length])];
        [self delete:self];
        break;
      case NSUpArrowFunctionKey:
        [self replaceCurrentCommandWith:[[history goToPrevious] getStr]];
        break;
      case NSDownArrowFunctionKey:
        [self replaceCurrentCommandWith:[[history goToNext] getStr]];
        break;
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
        case RETURN_CHAR:
            [self executeCurrentCommand:self];
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

- (void)moveToBeginningOfLine:(id)sender
{
  [self setSelectedRange:NSMakeRange(start,0)];
}

- (void)moveToEndOfLine:(id)sender
{
  [self moveToEndOfDocument:sender];
}

- (void)moveToBeginningOfParagraph:(id)sender
{
  [self setSelectedRange:NSMakeRange(start,0)];
}

- (void)moveToEndOfParagraph:(id)sender
{
  [self moveToEndOfDocument:sender];
}

- (void)moveLeft:(id)sender
{
  if ([self selectedRange].location > start)
    [super moveLeft:sender];
}

- (void)moveUp:(id)sender
{  
  // if we are on the first line of current command ==> replace current command by the previous one (history)
  //                                           else ==> apply the normal text editing behaviour.

  NSUInteger loc = [self selectedRange].location;
  [super moveUp:sender];
  
  if ([self selectedRange].location < start || [self selectedRange].location == loc) // moved before start of command || not moved because we are on the first line of the text view
  {
    if ([self selectedRange].location >= start-[prompt length] && [self selectedRange].location < start)
      // we are on the prompt, so we move to the start of the current command (the insertion point should not be on the prompt)
      [self setSelectedRange:NSMakeRange(start,0)];
    else
    {
      [self saveEditedCommand:self];
      [self replaceCurrentCommandWith:[[history goToPrevious] getStr]]; 
    } 
  }
}

- (void)moveDown:(id)sender
{
  // if we are on the last line of current command ==> replace current command by the next one (history)
  //                                          else ==> apply the normal text editing behaviour.
  NSUInteger loc = [self selectedRange].location;
  
  [super moveDown:sender];

  if ([self selectedRange].location == loc || [self selectedRange].location == [[self string] length]) // no movement || move to end of document because we are on the last line
  {
    [self saveEditedCommand:self];
    [self replaceCurrentCommandWith:[[history goToNext] getStr]];
  }
}

- (void)saveEditedCommand:(id)sender
{
  if (lineEdited) // if the current command has been edited by the user, save it in the history.
  {
    NSString *command = [[self string] substringFromIndex:start];
    if ([command length] > 0 && ![command isEqualToString:[history getMostRecentlyInsertedStr]])
    {
      [history addStr:command];
      [history goToPrevious];
    }
  }
}

- (void)parenthesizeCommand:(id)sender
{
  if ([self shouldChangeTextInRange:NSMakeRange(start,0) replacementString:@"("])
  {
    [self replaceCharactersInRange:NSMakeRange(start,0) withString:@"("];
    [self didChangeText];
  }
  if ([self shouldChangeTextInRange:NSMakeRange([self selectedRange].location,0) replacementString:@")"])
  {
    [self replaceCharactersInRange:NSMakeRange([self selectedRange].location,0) withString:@")"];
    [self didChangeText];
  }
  lineEdited = YES;
}

- (void)switchParserMode:(id)sender
{
  if (parserMode == NO_DECOMPOSE)
  {
    [self notifyUser:@"When pasting text in this console, newline and carriage return characters are now interpreted as command separators"];
    parserMode = DECOMPOSE;
    [[self undoManager] removeAllActions];
  }
  else
  {
    [self notifyUser:@"When pasting text in this console, newline and carriage return characters are now NOT interpreted as command separators"];
    parserMode = NO_DECOMPOSE;
    [[self undoManager] removeAllActions];
  }
}

-(NSString*)currentCommandLine
{
    return [[self string] substringFromIndex:start];
}

- (void)executeCurrentCommand:(id)sender
{
  NSString *command = [self currentCommandLine];
  long overflow;
  
  if (useMaxSize && (overflow = [[self string] length] - maxSize) > 0)
  {
    overflow = overflow + maxSize / 3;
    [self replaceCharactersInRange:NSMakeRange(0,overflow) withString:@""];
    start = start - overflow;
  }    
  
  last_command_start = start;
  if ([command length] > 0 && ![command isEqualToString:[history getMostRecentlyInsertedStr]]) {
     [history addStr:command];
   }
  [history goToLast];
  [self moveToEndOfDocument:self];
  [self insertTextAtCursor:@"\n"];
    id expr=nil;
    id result=@"";
    @try {
        result=[commandHandler compileAndEvaluate:command];
    } @catch ( NSException *e ) {
        result=[e description];
    }
    
//  [commandHandler command:command from:self]; // The command handler is notified
    if ( result && ![result isNil] ) {
//        NSLog(@"result class: %@ result: '%@'",[result class],result);
        [standardOut writeObject:result];
        [standardOut appendBytes:"\n" length:1];
    }
  [self insertTextAtCursor:prompt];
  [self scrollRangeToVisible:[self selectedRange]];
  start = [[self string] length];
  lineEdited = NO;
  [[self undoManager] removeAllActions];
}

- (void)paste:(id)sender
{
  NSPasteboard *pb = [NSPasteboard pasteboardByFilteringTypesInPasteboard:[NSPasteboard  generalPasteboard]];
  
  if ([pb availableTypeFromArray:[NSArray arrayWithObject:NSStringPboardType]] == NSStringPboardType)
  {
    NSMutableString *command = [[[pb stringForType:NSStringPboardType] mutableCopy] autorelease];
    
    switch (parserMode)
    {
      case DECOMPOSE: [command replaceOccurrencesOfString:@"\n" withString:@"\r" options:NSLiteralSearch range:NSMakeRange(0, [command length])]; 
                      break;
      case NO_DECOMPOSE: [command replaceOccurrencesOfString:@"\r" withString:@"\n" options:NSLiteralSearch range:NSMakeRange(0, [command length])]; 
                      break;                
    }
    
    [self putCommand:command];
  }  
}

- (void)putCommand:(NSString *)command
{   
    NSCharacterSet *separatorSet;
    NSScanner      *scanner = [NSScanner scannerWithString:command];
    NSString       *subCommand;

    separatorSet = [NSCharacterSet characterSetWithCharactersInString:@"\r"];
    [scanner setCharactersToBeSkipped:[NSCharacterSet characterSetWithCharactersInString:@""]]; // because Scanners skip whitespace and newline characters by default
            
    if ([self selectedRange].location < start)
      [self moveToEndOfDocument:self];
              
    if ([scanner scanUpToCharactersFromSet:separatorSet intoString:&subCommand])
      [self insertTextAtCursor:subCommand];
            
    while (![scanner isAtEnd])
    { 
      [scanner scanString:@"\r" intoString:NULL];
      subCommand = [[self string] substringFromIndex:start];
      last_command_start = start;
      if ([subCommand length] > 0)  [history addStr:subCommand];
      [self moveToEndOfDocument:self];
      [self insertTextAtCursor:@"\n"];
      [self scrollRangeToVisible:[self selectedRange]];
      [commandHandler command:subCommand from:self]; // notify the command handler
      // NSLog(@"puting command : %@",subCommand);
      [self insertTextAtCursor:prompt];
      start = [[self string] length];
      lineEdited = NO;
      subCommand = @"";  
      [scanner scanUpToCharactersFromSet:separatorSet intoString:&subCommand];
      if ([subCommand length] > 0)  [self insertTextAtCursor:subCommand];
      [self scrollRangeToVisible:[self selectedRange]];    
    } 
} 

- (void)putText:(NSString *)text
{
  [self moveToEndOfDocument:self];
  [self insertTextAtCursor:text];
  start = [[self string] length];
  [self scrollRangeToVisible:[self selectedRange]];
}

-(void)setupStdioForCommandHandler
{
    standardOut=[[MPWREPLViewPrinter streamWithTarget:[[self textStorage] mutableString] ] retain];
    [newInterpreter bindValue:[MPWPrintLiner streamWithTarget:standardOut] toVariableNamed:@"stdline"];
    [commandHandler bindValue:standardOut toVariableNamed:@"stdout"];

}

- (void)setCommandHandler:handler
{  
  if (shouldRetainCommandHandler)
  {
    [handler retain];
    [commandHandler release];
  }
  commandHandler = handler;
  [self setupStdioForCommandHandler];
}

- (void)setShouldRetainCommandHandler:(BOOL)shouldRetain
{
  if (shouldRetainCommandHandler == YES && shouldRetain == NO)
    [commandHandler release];
  else if (shouldRetainCommandHandler == NO && shouldRetain == YES) 
    [commandHandler retain];
  shouldRetainCommandHandler = shouldRetain;
}

- (BOOL)shouldRetainCommandHandler { return shouldRetainCommandHandler;}

- (void)showErrorRange:(NSRange)range
{
  NSTextStorage *theTextStore = [self textStorage];
 
  range.location += last_command_start;
  
  // The folowing instruction gives an better visual result.
  // Note that for it to work, showError:, the current method, must be called before outputing any error message
  // due to the use of the text's length in the test. 
  if (range.location + range.length >= [[self string] length] && range.length > 1) range.length--;

  if ([self shouldChangeTextInRange:range replacementString:nil]) 
  { 
    [theTextStore beginEditing];
    [theTextStore addAttributes:errorAttributes range:range];
    [theTextStore endEditing]; 
    [self didChangeText]; 
  }
}

// I implement this method, inherited from NSTextView,in order to prevent 
// the "smart delete" to delete parts of the prompt (in practice, this 
// was seen when the prompt ends with whithespace) 
- (NSRange)smartDeleteRangeForProposedRange:(NSRange)proposedCharRange 
{
  NSRange r = [super smartDeleteRangeForProposedRange:proposedCharRange]; 
  
  if (proposedCharRange.location >= start && r.location < start) 
  {
    r.length   = r.length - (start - r.location) ;
    r.location = start;
  }
  
  return r;   
}

///////////////////////// Delegate methods /////////////////

// Since a CLIView is his own delegate, it receives the NSTextView(its super class) delegate calls.

- (BOOL)textView:(NSTextView *)aTextView shouldChangeTextInRange:(NSRange)affectedCharRange replacementString:(NSString *)replacementString
{
  // policy: do not accept a modification outside the current command.
    
  if (replacementString && affectedCharRange.location < start)
  {
      NSBeep();
      return NO;
  }
  else
  {
    lineEdited = YES;
    return YES;
  }
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



@end
