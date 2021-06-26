//
//  MPWInstanceVariable.h
//  Arch-S
//
//  Created by Marcel Weiher on 20/07/2005.
//  Copyright 2005 Marcel Weiher. All rights reserved.
//

#import <MPWFoundation/MPWFoundation.h>


@interface MPWInstanceVariable : MPWObject {
	NSString	*name;
	NSString	*type;
	long			offset;
}

-initWithName:(NSString*)newName offset:(int)newOffset type:(NSString*)newType;
-(long)offset;
-(NSString*)name;
-(NSString*)type;
-valueInContext:anObject;
-(void)setValue:newValue inContext:anObject;
-(NSString*)objcType;
@end
