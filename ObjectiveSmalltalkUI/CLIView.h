/* CLIView.h Copyright (c) 1998-2009 Philippe Mougin.    */
/*   This software is open source. See the license.  */  

/* CLIView is the public API for a Command Line Interface component.*/

#import <AppKit/AppKit.h>

@interface CLIView : NSView
{
  id commandHandler; // fake outlet for easy parsing in interface builder. The real commandHandler 
                     // instance variable is inside ShellView.  
}

- (id)commandHandler;                              // Return the current command handler. 
- (CGFloat)fontSize;                               // Return the font size. 
- (void)notifyUser:(NSString *)message;            // Point the message to the attention of the user 
- (void)putCommand:(NSString *)command;            // A programmatic way to put a command in the CLI view.

- (void)putText:(NSString *)text;                  // Put the text passed as argument in the CLIView. 
                                                   // Typically, you use this method to show the user the result of his last command.

- (void)setCommandHandler:handler;                 // Set the command handler.

- (void)setShouldRetainCommandHandler:(BOOL)shouldRetain;  // Set whether the command handler should be retained or not by the CLIView.
                                                           // By default, the command handler is retained. 
- (void)setFontSize:(CGFloat)theSize;              // Set the font size. 
- (BOOL)shouldRetainCommandHandler;                // Return YES if the command handler is retained, NO otherwise.

- (void)showErrorRange:(NSRange)range;             // Highlights a part of the last command entered by the user. The range is relative
                                                   // to the start of the considered command. You must call this method before putting
                                                   // any text (with -putText:) after the user entered his command. 

@end
