//
//  MPWScheme.h
//  MPWTalk
//
//  Created by Marcel Weiher on 6.1.10.
//  Copyright 2010 Marcel Weiher. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol Scheme <NSObject>

-bindingForName:(NSString*)variableName inContext:aContext;


@end

@interface MPWScheme : NSObject {

}

+scheme;
-evaluateIdentifier:anIdentifer withContext:aContext;
-bindingForName:(NSString*)variableName inContext:aContext;
-get:uriString;
-get:uri parameters:params;



@end
