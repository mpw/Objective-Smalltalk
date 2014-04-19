//
//  MPWScheme.h
//  MPWTalk
//
//  Created by Marcel Weiher on 6.1.10.
//  Copyright 2010 Marcel Weiher. All rights reserved.
//

#import <Foundation/Foundation.h>

@class MPWBinding,MPWIdentifier;

@protocol Scheme <NSObject>

-valueForBinding:(MPWBinding*)aBinding;
-(MPWBinding*)bindingWithIdentifier:(MPWIdentifier*)anIdentifier withContext:aContext;
-(MPWBinding*)bindingForName:(NSString*)variableName inContext:aContext;
-(BOOL)isBoundBinding:(MPWBinding*)aBinding;

@end


@interface MPWScheme : NSObject <Scheme> {

}

+scheme;
-evaluateIdentifier:anIdentifer withContext:aContext;
-get:uriString;
-get:uri parameters:params;

-(NSArray *)completionsForPartialName:(NSString *)partialName inContext:aContext;



@end
