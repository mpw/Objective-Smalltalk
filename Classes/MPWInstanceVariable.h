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

@property (assign, nonatomic, readonly) unsigned char objcTypeCode;

-(instancetype)initWithName:(NSString*)newName offset:(int)newOffset type:(STTypeDescriptor*)newType;
-(long)offset;
-valueInContext:anObject;
-(void)setValue:newValue inContext:anObject;
-(NSString*)objcType;
-(NSString*)typeName;  // should probably deprecate

@end
