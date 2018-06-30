//
//  MPWScheme.h
//  MPWTalk
//
//  Created by Marcel Weiher on 6.1.10.
//  Copyright 2010 Marcel Weiher. All rights reserved.
//

#import <MPWFoundation/MPWFoundation.h>

@class MPWBinding,MPWIdentifier;

@protocol Scheme <NSObject>

-(MPWBinding*)bindingWithIdentifier:(MPWIdentifier*)anIdentifier withContext:aContext;
-(MPWBinding*)bindingForName:(NSString*)variableName inContext:aContext;
-(BOOL)isBoundBinding:(MPWBinding*)aBinding;

@end


@interface MPWScheme : MPWAbstractStore <Scheme> {

}


-(NSArray *)completionsForPartialName:(NSString *)partialName inContext:aContext;



@end
