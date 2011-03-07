//
//  MPWInstanceVariable.h
//  MPWTalk
//
//  Created by Marcel Weiher on 20/07/2005.
//  Copyright 2005 Marcel Weiher. All rights reserved.
//

#import <MPWFoundation/MPWFoundation.h>


@interface MPWInstanceVariable : MPWObject {
	NSString	*name;
	NSString	*type;
	int			offset;
}

-initWithName:(NSString*)newName offset:(int)newOffset type:(NSString*)newType;
-(int)offset;
-(NSString*)name;
-(NSString*)type;
-valueInContext:anObject;
-(void)setValue:newValue inContext:anObject;

@end
