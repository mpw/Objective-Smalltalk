//
//  MPWFileBinding.h
//  MPWShellScriptKit
//
//  Created by Marcel Weiher on 6/11/08.
//  Copyright 2008 Apple. All rights reserved.
//

#import <MPWFoundation/MPWBinding.h>


@interface MPWFileBinding : MPWBinding {
    BOOL ignoreChanges;
    NSTimeInterval lastRead,lastWritten;
}

@property (nonatomic,strong) NSString *parentPath;

-(NSString*)fancyPath;
-source;

@end
