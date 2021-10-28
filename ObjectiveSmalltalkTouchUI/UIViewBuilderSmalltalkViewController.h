//
//  ViewController.h
//  UIViewBuilderMockup
//
//  Created by Marcel Weiher on 09.01.21.
//  Copyright © 2021 Marcel Weiher. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <MPWFoundation/MPWFoundation.h>
#import "ViewBuilderPreviewNotification.h"



@interface UIViewBuilderSmalltalkViewController : UIViewController<ViewBuilderUIKitPreviewNotification>

@property (nonatomic, strong) IBOutlet UITextView *log;
@property (nonatomic, strong) IBOutlet UIView *preview;

@end

