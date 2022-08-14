//
//  MPWMethodType.m
//  psdb
//
//  Created by Marcel Weiher on 22/01/2006.
//  Copyright 2006 Marcel Weiher. All rights reserved.
//

#import "MPWMethodType.h"


@implementation MPWMethodType

objectAccessor(NSString*, typeName, setTypeName )
objectAccessor(NSString*, methodClassName, setMethodClassName )

-initWithName:(NSString*)name className:(NSString*)className
{
	self = [super init];
	[self setTypeName:name];
	[self setMethodClassName:className];
	return self;
}

+methodTypeWithName:(NSString*)name className:(NSString*)className
{
	return [[[self alloc] initWithName:name className:className] autorelease];
}

-(Class)methodClass
{
	return NSClassFromString([self methodClassName]);
}

//-(void)encodeWithCoder:aCoder
//{
//    [super encodeWithCoder:aCoder];
//    encodeVar( aCoder, typeName );
//    encodeVar( aCoder, methodClassName );
//}
//
//-initWithCoder:aCoder
//{
//    self=[super initWithCoder:aCoder];
//    decodeVar( aCoder, typeName );
//    decodeVar( aCoder, methodClassName );
//    return self;
//}


-(void)dealloc
{
	[typeName release];
	[methodClassName release];
	[super dealloc];
}

@end
