//
//  MPWSchemeFilesystem.h
//  Arch-S
//
//  Created by Marcel Weiher on 11/3/11.
//  Copyright (c) 2012 Marcel Weiher. All rights reserved.
//

#import <Foundation/Foundation.h>

@class MPWScheme;

@interface MPWSchemeFilesystem : NSObject

@property (nonatomic,strong) MPWScheme *scheme,*extensionIcons,*fileIcons;

@end
