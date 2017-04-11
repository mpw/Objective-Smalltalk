//
//  MPWMethodHeader.h
//  MPWTalk
//
//  Created by Marcel Weiher on 12/05/2005.
//  Copyright 2005 Marcel Weiher. All rights reserved.
//

#import <MPWFoundation/MPWFoundation.h>

@class MPWStScanner;

@interface MPWMethodHeader : MPWObject {
	NSString	*methodName;
	NSString	*returnTypeName;
	NSMutableArray		*parameterNames;
	NSMutableArray		*parameterTypes;
	NSMutableArray		*methodKeyWords;

}

objectAccessor_h( NSString , methodName, setMethodName )

+methodHeaderWithString:(NSString*)aString;
-initWithString:(NSString*)aString;
-initWithScanner:(MPWStScanner*)scanner;
-(NSString*)returnTypeName;
-(NSString*)headerString;
-typeString;


-(int)numArguments;
-argumentNameAtIndex:(int)anIndex;
-argumentTypeAtIndex:(int)anIndex;
-(const char*)typeSignature;
-(NSMutableArray*)parameterNames;
-(SEL)selector;

-typeStringForTypeName:aType;

@end
