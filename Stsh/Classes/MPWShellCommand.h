//
//  MPWShellCommand.h
//  MPWShellScriptKit
//
//  Created by Marcel Weiher on 22/12/2005.
//  Copyright 2005 Marcel Weiher. All rights reserved.
//

#import <MPWFoundation/MPWFoundation.h>


@interface MPWShellCommand : MPWObject {
    id  name;
    BOOL returnsLines;
}

-initWithName:aName;
-run:firstArg;
-run:firstArg with:secondArg;
-run:firstArg with:secondArg with:thirdArg with:fourthArg;


@end
