//
//  MPWAbstractShellCommand
//  MPWShellScriptKit
//
//  Created by Marcel Weiher on 22/12/2005.
//  Copyright 2005 Marcel Weiher. All rights reserved.
//

#import <MPWFoundation/MPWFoundation.h>


@interface MPWAbstractShellCommand : MPWObject {
    NSString *name;
    BOOL returnsLines;
}

-initWithName:aName;
-run:firstArg;
-runProcess;

//-run:firstArg with:secondArg;
//-run:firstArg with:secondArg with:thirdArg with:fourthArg;

-with:firstArg;

- (NSString *)name;
- (BOOL)returnsLines;
@end
