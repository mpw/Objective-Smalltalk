//
//  MPWInstanceVariable.h
//  Arch-S
//
//  Created by Marcel Weiher on 20/07/2005.
//  Copyright 2005 Marcel Weiher. All rights reserved.
//

#import <ObjectiveSmalltalk/STVariableDefinition.h>

@class STTypeDescriptor;

@interface MPWInstanceVariable : STVariableDefinition {
	long			    offset;
}

-initWithName:(NSString*)newName offset:(int)newOffset type:(NSString*)newType;
-(long)offset;
-valueInContext:anObject;
-(void)setValue:newValue inContext:anObject;
-(NSString*)objcType;
@end
