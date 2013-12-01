//
//  MPWExternalCommand.h
//  MPWShellScriptKit
//
//  Created by Marcel Weiher on 6/2/07.
//  Copyright 2007 Marcel Weiher. All rights reserved.
//

#import <Stsh/MPWShellCommand.h>


@interface MPWExternalCommand : MPWShellCommand {
    id  path;
	BOOL isText;
}

boolAccessor_h( isText, setIsText )

@end
