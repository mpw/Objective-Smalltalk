//
//  MPWScheme.h
//  Arch-S
//
//  Created by Marcel Weiher on 6.1.10.
//  Copyright 2010 Marcel Weiher. All rights reserved.
//

#import <MPWFoundation/MPWFoundation.h>

@class MPWBinding,STIdentifier;

@protocol Scheme <NSObject>

-(MPWBinding*)bindingWithIdentifier:(STIdentifier*)anIdentifier withContext:aContext;
-(MPWBinding*)bindingForName:(NSString*)variableName inContext:aContext;
-bindingForReference:aReference inContext:aContext;

@end

@interface MPWAbstractStore(SchemeCompatibility) <Scheme>

@end

@interface MPWScheme : MPWAbstractStore  {

}

@end


@interface MPWAbstractStore(completion)

-(NSArray *)completionsForPartialName:(NSString *)partialName inContext:aContext;

@end
