/* CLIView.m Copyright (c) 1998-2009 Philippe Mougin.  */
/*   This software is open source. See the license.  */  

/*

The organisation of the view hierarchy:

      ----- CLIView --------------------------------------
      |                                                  |
      | ----- NSScrollView ----------------------------  |
      | |                                             |  |
      | |  ----- ShellView -------------------------  |  |
      | |  | prompt>                               |  |  |
      | |  |                                       |  |  |
      | |  |                                       |  |  |
      | |  |                                       |  |  |
      | |  |                                       |  |  |
      | |  |                                       |  |  |
      | |  -----------------------------------------  |  |
      | |                                             |  |
      | -----------------------------------------------  |
      |                                                  |
      ----------------------------------------------------

A CLIView has one subview: an NSScrollView.
 
This NSScrollView has a ShellView as document view.

The ShellView is the view that displays the prompt, receive the keyboard events from the user, display
the commands entered by the user and the results of those commands etc.  

*/

#import "CLIView.h"
#import "ShellView.h"
#import <ObjectiveSmalltalk/STCompiler.h>

@interface CLIView(CLIViewPrivate)
- (ShellView *)shellView;
@end

@implementation CLIView

//- (BOOL)acceptsFirstResponder {return YES;}
//- (BOOL)acceptsFirstResponder {NSLog(@"CLIView acceptsFirstResponder"); return YES;}

//- (BOOL)becomeFirstResponder {NSLog(@"CLIView becomeFirstResponder"); return YES;}

//- (BOOL)acceptsFirstMouse:(NSEvent *)theEvent {NSLog(@"CLIView acceptsFirstMouse:"); return YES;}


- (id)commandHandler {return [[self shellView] commandHandler];}

- (void)encodeWithCoder:(NSCoder *)coder
{
  id sub; 
  BOOL shouldRetainCommandHandler = [self shouldRetainCommandHandler] ;
  id _commandHandler = [self commandHandler];
 
  sub = [[[self subviews] objectAtIndex:0] retain];   // I can't encode the shellView since its superclass
                                                      // (NSTextView) doesn't 
                                                      // comforms to NSCoding (note: this is true under 
                                                      // OpenStep, it seems to have changed with OSX) 
  [sub removeFromSuperview];                          // So I remove it (actually I remove it and its 
                                                      // superview (the NSScrollView)) before encoding 
                                                      // the view hierarchy

  [super encodeWithCoder:coder];                      // This will encode the view hierarchy
  
  if ( [coder allowsKeyedCoding] ) 
  {
    [coder encodeBool:shouldRetainCommandHandler forKey:@"shouldRetainCommandHandler"];
    [coder encodeConditionalObject:_commandHandler forKey:@"commandHandler"];
  }
  else
  {
    [coder encodeValueOfObjCType:@encode(BOOL) at:&shouldRetainCommandHandler];
    [coder encodeConditionalObject:_commandHandler];
  }  

  [self addSubview:sub];                              // I reinstall the NSScrollView in the view hierarchy
  [sub release];
}

- (CGFloat)fontSize
{ return [[[self shellView] font] pointSize]; }

- (id) _privateSetup  // construction and configuration of the view hierarchy
{
    NSScrollView *scrollview =[[[NSScrollView alloc] initWithFrame:[self bounds]] autorelease];
    NSSize contentSize = [scrollview contentSize];
    ShellView *shellView; 

    [scrollview setBorderType:NSNoBorder];
    [scrollview setHasVerticalScroller:YES];
    [scrollview setHasHorizontalScroller:NO];
    [scrollview setAutoresizingMask:NSViewWidthSizable | NSViewHeightSizable]; 

    shellView = [[[ShellView alloc] initWithFrame:NSMakeRect(0, 0,[scrollview contentSize].width, [scrollview contentSize].height)] autorelease];
    [shellView setMinSize:(NSSize){0.0, contentSize.height}];
    [shellView setMaxSize:(NSSize){1e7, 1e7}];
    [shellView setVerticallyResizable:YES];
    [shellView setHorizontallyResizable:NO];
    [shellView setAutoresizingMask:NSViewWidthSizable ]; 
    [[shellView textContainer] setWidthTracksTextView:YES];

    [scrollview setDocumentView:shellView];
    [self addSubview:scrollview];
    
    [self setCommandHandler:[STCompiler compiler]];

    return self;
}

- (id)initWithCoder:(NSCoder *)coder
{
  BOOL shouldRetainCommandHandler;

  self = [super initWithCoder:coder];
  [self _privateSetup];
  
  if ( [coder allowsKeyedCoding] ) 
  {
    shouldRetainCommandHandler =[coder decodeBoolForKey:@"shouldRetainCommandHandler"];
    [self setShouldRetainCommandHandler:shouldRetainCommandHandler];
    [self setCommandHandler:[coder decodeObjectForKey:@"commandHandler"]];
  }
  else
  {
    [coder decodeValueOfObjCType:@encode(BOOL) at:&shouldRetainCommandHandler];
    [self setShouldRetainCommandHandler:shouldRetainCommandHandler];
    [self setCommandHandler:[coder decodeObject]];
  }  
  
  [self setAutoresizesSubviews:YES];
  return self;
}

- (id)initWithFrame:(NSRect)frameRect
{
  if (self = [super initWithFrame:frameRect])
  {
    [self _privateSetup];
    [self setAutoresizesSubviews:YES];    
    return self;
  }
  return nil;
}

- (void)notifyUser:(NSString *)message {[[self shellView] notifyUser:message];}

- (void)putCommand:(NSString *)command { [[self shellView] putCommand:command];}

- (void)putText:(NSString *)text { [[self shellView] putText:text];}

- (void)setCommandHandler:handler { [[self shellView] setCommandHandler:handler];}

- (void)setFontSize:(CGFloat)theSize { [[self shellView] setFont:[NSFont userFixedPitchFontOfSize:theSize]];}

- (void)setShouldRetainCommandHandler:(BOOL)shouldRetain { [[self shellView] setShouldRetainCommandHandler:shouldRetain];}

- (BOOL)shouldRetainCommandHandler { return [[self shellView] shouldRetainCommandHandler]; }

- (void)showErrorRange:(NSRange)range { [[self shellView] showErrorRange:range];}


// Private

- (ShellView *)shellView
{
  return [[[self subviews] objectAtIndex:0] documentView];
}

@end
