//
//  MPWMethodHeader.h
//  Arch-S
//
//  Created by Marcel Weiher on 12/05/2005.
//  Copyright 2005 Marcel Weiher. All rights reserved.
//

#import <MPWFoundation/MPWFoundation.h>

@class MPWStScanner,STVariableDefinition,STTypeDescriptor;

@interface MPWMethodHeader : MPWObject {
	NSString	*methodName;
    STTypeDescriptor	*returnType;
	NSMutableArray		*parameterVars;
	NSMutableArray		*methodKeyWords;
}

objectAccessor_h(NSString*, methodName, setMethodName )

+methodHeaderWithString:(NSString*)aString;
-initWithString:(NSString*)aString;
-initWithScanner:(MPWStScanner*)scanner;
-(NSString*)returnTypeName;
-(STTypeDescriptor*)returnType;
-(NSString*)headerString;
-typeString;


-(int)numArguments;
-(STVariableDefinition*)variableDefAtIndex:(int)anIndex;
-(NSString*)argumentNameAtIndex:(int)anIndex;
-(STTypeDescriptor*)argumentTypeAtIndex:(int)anIndex;
-(NSString*)argumentTypeNameAtIndex:(int)anIndex;
-(const char*)typeSignature;
-(SEL)selector;


@end
