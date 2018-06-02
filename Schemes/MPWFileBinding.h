//
//  MPWFileBinding.h
//  MPWShellScriptKit
//
//  Created by Marcel Weiher on 6/11/08.
//  Copyright 2008 Apple. All rights reserved.
//

#import <MPWFoundation/MPWBinding.h>


@interface MPWFileBinding : MPWBinding {
//	id	url;
    BOOL ignoreChanges;
    NSTimeInterval lastRead,lastWritten;
}

@property (nonatomic,strong) NSString *parentPath;

-url;
-initWithURLString:(NSString*)urlString;
-initWithURL:(NSURL*)newURL;
-initWithPath:(NSString*)path;

-(NSString*)fancyPath;

@end
