//
//  MPWInstanceVariable.m
//  Arch-S
//
//  Created by Marcel Weiher on 20/07/2005.
//  Copyright 2005 Marcel Weiher. All rights reserved.
//

#import "MPWInstanceVariable.h"
#import "STTypeDescriptor.h"

@implementation MPWInstanceVariable

longAccessor( offset, setOffset )

-(instancetype)initWithName:(NSString*)newName offset:(int)newOffset type:(STTypeDescriptor*)newType
{
	self=[super initWithName:newName type:(STTypeDescriptor*)newType];
	[self setOffset:newOffset];
	return self;
}

#define pointerToVarInObject( anObject )  ((id*)(((char*)anObject) + offset))


-valueInContext:anObject
{
	id result=nil;
	if ( anObject ) {
//        NSLog(@"ivar %@ get value at offset: %ld",name,offset);
		result= *pointerToVarInObject( anObject );
	}
	return result;
}

-(void)setValue:newValue inContext:anObject
{
	id *ptr = pointerToVarInObject( anObject );
    switch (self.objcTypeCode) {
        case '@':
            if ( anObject &&  *ptr != newValue ) {
                [newValue retain];
                [*ptr release];
                *ptr = newValue;
            }
            break;
        case 'i':
        case 'l':
        case 'b':
        case 'B':
            *(int*)ptr = (int)[newValue integerValue];
            break;

    }
//   NSLog(@"ivar %@ set Value: %@ at offset: %ld",name,newValue,offset);

}

-(NSString*)typeName
{
    return [self.type name];
}

-(NSString*)objcType
{
    return [NSString stringWithFormat:@"%c",self.objcTypeCode];
}

-(unsigned char)objcTypeCode
{
    return self.type.objcTypeCode;
}

@end


