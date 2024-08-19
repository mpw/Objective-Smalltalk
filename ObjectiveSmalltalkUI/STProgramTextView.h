//
//  STProgramTextView.h
//  ObjectiveSmalltalkUI
//
//  Created by Marcel Weiher on 19.08.24.
//

#import <ObjectiveSmalltalkUI/ObjectiveSmalltalkUI.h>

NS_ASSUME_NONNULL_BEGIN

@class STCompiler;

@interface STProgramTextView : MPWProgramTextView

@property (nonatomic, strong)  STCompiler *compiler;

-(IBAction)doIt:sender;
-(IBAction)printIt:sender;

@end

NS_ASSUME_NONNULL_END
