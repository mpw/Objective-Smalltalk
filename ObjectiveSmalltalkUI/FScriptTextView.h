/* FScriptTextView.h Copyright (c) 2002-2009 Philippe Mougin.  */
/*   This software is open source. See the license.  */ 

#import <AppKit/AppKit.h>
 
@interface FScriptTextView : NSTextView {

}

+ (void)initialize;

+ (void)registerClassNameForCompletion: (NSString *)className;
+ (void)registerMethodNameForCompletion:(NSString *)methodName;

@end
