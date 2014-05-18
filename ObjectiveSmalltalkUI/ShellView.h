/* ShellView.h Copyright (c) 1998-2009 Philippe Mougin.  */
/*   This software is open source. See the license.  */  

#import <AppKit/AppKit.h>

@class FSCommandHistory;

typedef enum {DECOMPOSE,NO_DECOMPOSE} T_parser_mode;

@protocol ShellViewCommandHandler <NSObject>
- (void)command:(NSString *)command from:(id)sender;
@end

@class MPWByteStream;

@interface ShellView : NSTextView <NSTextViewDelegate>
{
  NSString *prompt;
    MPWByteStream *stdout;
  NSUInteger start;                   // The start of the current command (i.e. the command beign edited) 
                                      // in term of its character position in the whole NSTextView.
  
  id<ShellViewCommandHandler> commandHandler; // The object that is notified when a command is entered.     
  FSCommandHistory *history;                  // The history of entered command.
  T_parser_mode parserMode;           // (parserMode == DECOMPOSE)  ==> When some text is "pasted" in by the user, each line
                                      //                                of this text is considered to be an independent command.
                                      // (parserMode == NO_DECOMPOSE)  ==> the entire "pasted" text forms only one command. 
  
  BOOL lineEdited;                    // Did the user edit the current command ?
  long last_command_start;            // The start of the last command entered (its character position).
  BOOL shouldRetainCommandHandler;       
  long maxSize;                       // The maximum size of the shellView content in term of character. -1 means no limit.
                                      // When the limit is reached, the oldest contents will be deleted to make room.
                                      // This limit is just an aproximation. At some points in time the size will
                                      // be bigger, at some other points it will be smaller. 
                                      // This is used because it has been noted that if we let the content of the view
                                      // becoming too big then the user interface slow down considerably (with the new NSText in early OpenStep releases).  
}

- (id)commandHandler;
- (void)dealloc;
- (id)initWithFrame:(NSRect)frameRect;
- (id)initWithFrame:(NSRect)frameRect prompt:(NSString *)thePrompt historySize:(NSInteger)theHistorySize commandHandler:(id)theCommandHandler;
- (void)keyDown:(NSEvent *)theEvent;

// Overrides for NSResponder (NSStandardKeyBindingMethods) Category methods

- (void)moveToBeginningOfLine:(id)sender;
- (void)moveToEndOfLine:(id)sender;
- (void)moveToBeginningOfParagraph:(id)sender;
- (void)moveToEndOfParagraph:(id)sender;
- (void)moveLeft:(id)sender;
- (void)moveDown:(id)sender;
- (void)moveUp:(id)sender;

- (void)saveEditedCommand:sender;
- (void)parenthesizeCommand:(id)sender;
- (void)switchParserMode:(id)sender;
- (void)executeCurrentCommand:(id)sender;

- (void)notifyUser:(NSString *)notification;
- (void)paste:(id)sender;
- (void)putCommand:(NSString *)command;
- (void)putText:(NSString *)text;
- (void)setCommandHandler:handler;
- (void)setShouldRetainCommandHandler:(BOOL)shouldRetain;
- (BOOL)shouldRetainCommandHandler; 
- (void)showErrorRange:(NSRange)range;
- (BOOL)textView:(NSTextView *)aTextView shouldChangeTextInRange:(NSRange)affectedCharRange replacementString:(NSString *)replacementString;

@end
