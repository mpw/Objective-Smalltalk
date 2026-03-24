//
//  STViewHarness.h
//  ObjectiveSmalltalkUI
//
//  Created by Marcel Weiher on 18.03.26.
//

#import <Cocoa/Cocoa.h>
#import <ObjectiveSmalltalk/ObjectiveSmalltalk.h>

NS_ASSUME_NONNULL_BEGIN

@interface STViewHarness : NSViewController <ClassCompiled>

-(IBAction)triggerRedisplay:(id)sender;

@property (nonatomic, strong ) IBOutlet NSTextView *logView;
@property (nonatomic, strong ) IBOutlet NSView *slotForContentView;


@end

NS_ASSUME_NONNULL_END
