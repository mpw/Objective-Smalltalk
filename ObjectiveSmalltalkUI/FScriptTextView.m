/* FScriptTextView.m Copyright (c) 2002-2009 Philippe Mougin.  */
/*   This software is open source. See the license.  */ 
#import "FScriptTextView.h"
//#import "FSMiscTools.h"
//#import "FSArray.h"
//#import "FSCompiler.h"

#import "MPWStCompiler.h"

#import <objc/objc-class.h>
//#import "FSConstantsInitialization.h"
//#import <ExceptionHandling/NSExceptionHandler.h>

static NSMutableArray *completionStrings;
static NSArray *constants;
static NSMutableCharacterSet *letterDigitUnderscoreCharacterSet;

@implementation FScriptTextView

+ (void)registerClassNameForCompletion:(NSString *)className
{
  if (completionStrings && ![completionStrings containsObject:className])
  {
    [completionStrings insertObject:className atIndex:0];
  }
}

+ (void)registerMethodNameForCompletion:(NSString *)methodName
{
  if (completionStrings && ![completionStrings containsObject:methodName])
  {
    [completionStrings insertObject:methodName atIndex:0];
  }
}


+ completionStrings // private; for testing purpose
{
  return completionStrings;
}

+ (void)buildCompletionStrings
{
#if 0
  NSMutableSet *completionStringSet; 
  NSInteger i,j;
//  unsigned int exceptionHandlingMask = [[NSExceptionHandler defaultExceptionHandler] exceptionHandlingMask];
  NSUInteger classCount;
  Class *classes;

  completionStringSet = [[[NSMutableSet alloc] initWithCapacity:80000] autorelease];

  classes = allClasses(&classCount);
    
//  [[NSExceptionHandler defaultExceptionHandler] setExceptionHandlingMask:42];

  for (j = 0 ; j < classCount; j++)
  {
//    NS_DURING
  
      //NSLog(@"**************************************************************");
     // NSLog(NSStringFromClass([classes objectAtIndex:j]));
      
      // Register class name 
      [completionStringSet addObject:NSStringFromClass(classes[j])];
    
#ifdef __LP64__
    unsigned methodCount; 
    Method *methods;
	  
	  // Register class selectors
	methods = class_copyMethodList(classes[j], &methodCount);
    for (i = 0; i < methodCount; i++) [completionStringSet addObject:[FSCompiler stringFromSelector:method_getName(methods[i])]];      
	  free(methods);
	  
	  // Register meta-class selectors
    methods = class_copyMethodList(classes[j]->isa, &methodCount);
	for (i = 0; i < methodCount; i++) [completionStringSet addObject:[FSCompiler stringFromSelector:method_getName(methods[i])]];      
	free(methods);
#else
    struct objc_method_list *mlist;
    void *iterator = 0;

      // Register class selectors
	while ( mlist = class_nextMethodList(classes[j], &iterator ) )
      for (i = 0; i < mlist->method_count; i++)
      {
          //NSLog([FSCompiler stringFromSelector:mlist->method_list[i].method_name]);
        [completionStringSet addObject:[FSCompiler stringFromSelector:mlist->method_list[i].method_name]];
      }
      // Register meta-class selectors
    while ( mlist = class_nextMethodList(classes[j]->isa, &iterator ) )  // Note: using classOrMetaClass instead of ->isa crashed the application for some classes (!)
      for (i = 0; i < mlist->method_count; i++)
      {
        //NSLog(@"            meta");
        //NSLog([FSCompiler stringFromSelector:mlist->method_list[i].method_name]);
        [completionStringSet addObject:[FSCompiler stringFromSelector:mlist->method_list[i].method_name]];
      }
#endif
		
//    NS_HANDLER
//        NSLog(@"F-Script: problem while initializing the completion system for class %@. The following exception was encountered: %@ %@", NSStringFromClass([classes objectAtIndex:j]), [localException name], [localException reason]);
//    NS_ENDHANDLER
  }
    
  // Restore the original exception handling mask   
//  [[NSExceptionHandler defaultExceptionHandler] setExceptionHandlingMask:exceptionHandlingMask];  

  // Register predefined constants
  [completionStringSet addObjectsFromArray:constants];
  
  //NSLog(@"nb completion strings = %d",[completionStringSet count]);

  free(classes);

  [completionStrings release];
  completionStrings = [[completionStringSet allObjects] mutableCopy]; 
  [completionStrings sortUsingSelector:@selector(compare:)];
#endif
}

+ (void)buildCompletionStrings:(NSNotification *)notification
{
  [self buildCompletionStrings];
}

+ (void)initialize
{
  static BOOL tooLate = NO;
  if ( !tooLate )
  {
    NSMutableDictionary *d; 
    NSAutoreleasePool *pool;

    tooLate = YES;
    pool = [[NSAutoreleasePool alloc] init];

    letterDigitUnderscoreCharacterSet = [[NSMutableCharacterSet letterCharacterSet] retain];
    [letterDigitUnderscoreCharacterSet formUnionWithCharacterSet:[NSCharacterSet decimalDigitCharacterSet]];
    [letterDigitUnderscoreCharacterSet addCharactersInString:@"_"];
    
    d = [[NSMutableDictionary alloc] initWithCapacity:8500];
//    FSConstantsInitialization(d);
    constants = [[d allKeys] retain];
    [d release];
    completionStrings = nil;   

    [pool release];
  }
} 

- (NSArray *)completionsForPartialWordRange:(NSRange)charRange indexOfSelectedItem:(NSInteger *)index
{
  NSString *stringToComplete;
  NSMutableArray *result = [NSMutableArray array];
  NSUInteger i, count; 
  
  stringToComplete = [[self string] substringWithRange:charRange];
  //NSLog(stringToComplete); 
   
  if (completionStrings == nil)
  {
    [FScriptTextView buildCompletionStrings];
    [[NSNotificationCenter defaultCenter] addObserver:[self class] selector:@selector(buildCompletionStrings:) name:NSBundleDidLoadNotification object:nil];
  }

  for (i = 0, count = [completionStrings count]; i < count; i++)
  {
    NSString *completionCandidate = [completionStrings objectAtIndex:i];
    if ([completionCandidate hasPrefix:stringToComplete])
      [result addObject:completionCandidate];
  }
  
  if ([[self delegate] respondsToSelector:@selector(textView:completions:forPartialWordRange:indexOfSelectedItem:)])
    return [[self delegate] textView:self completions:result forPartialWordRange:charRange indexOfSelectedItem:index];
  else
    return result;  
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
  else [super insertCompletion:word forPartialWordRange:charRange movement:movement isFinal:flag];
}

- (void)keyDown:(NSEvent *)theEvent  // Called by the AppKit when the user press a key.
{
  // NSLog(@"characters = %@",[theEvent characters]);
  // NSLog(@"charactersIgnoringModifiers = %@",[theEvent charactersIgnoringModifiers]);
  // NSLog(@"char0 = %d", (int)[[theEvent characters] characterAtIndex:0]);
  // NSLog(@"modifierFlags = %x",[theEvent modifierFlags]);
  
  if ([theEvent type] != NSKeyDown) 
  {
    [super keyDown:theEvent];
    return;
  } 
  
  if ([[theEvent charactersIgnoringModifiers] isEqualToString:@"/"] && ([theEvent modifierFlags] & NSControlKeyMask))
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
  else [super keyDown:theEvent];
}


@end
