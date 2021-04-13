//
//  MPWVARBinding.m
//  Arch-S
//
//  Created by Marcel Weiher on 17.12.09.
//  Copyright 2009 Marcel Weiher. All rights reserved.
//

#import "MPWVARBinding.h"
#import <MPWFoundation/MPWFoundation.h>


@implementation NSObject(valueForPathComponent)

-valueForPathComponent:(NSString*)pathComponent
{
    return [self valueForKey:pathComponent];
}

-(void)objst_addObserver:anObserver forKey:aKey
{
    //    NSLog(@"%@ objst_addObserver: %@",self,anObserver);
    [self addObserver:anObserver forKeyPath:aKey options:0 context:NULL];
}


@end

@implementation MPWVARBinding

idAccessor( baseObject, setBaseObject )


-initWithBaseObject:newBase pathComponents:(NSArray*)newPathComponents
{
	self=[super init];
    self.reference = [[[MPWGenericReference alloc] initWithPathComponents:newPathComponents scheme:nil] autorelease];
	[self setBaseObject:newBase];
	return self;
	
}

-path
{
    return [[self pathComponents] componentsJoinedByString:@"/"];
}

-pathComponents
{
    return [(MPWGenericReference*)self.reference pathComponents];
}

-initWithBaseObject:newBase path:newPath
{
	return [self initWithBaseObject:newBase pathComponents:[newPath componentsSeparatedByString:@"/"]];
}

+bindingWithBaseObject:newBase path:newPath
{
    return [[[self alloc] initWithBaseObject:newBase path:newPath] autorelease];
}


-(BOOL)isBound
{
	return YES;
}

-(NSString*)finalKey
{
    return [[self pathComponents] lastObject];
}

-(id)_objectToIndex:(int)anIndex
{
    if ( anIndex < 0 ) {
        anIndex=(int)[[self pathComponents] count]+anIndex;
    }
	anIndex=MIN(anIndex, (int)[[self pathComponents] count]);
	id result=baseObject;
	int i;
	for (i=0;i<anIndex;i++) {
		result=[result valueForPathComponent:[[self pathComponents] objectAtIndex:i]];
	}
	return result;
}

//-_value
//{
//    return [self _objectToIndex:(int)[[self pathComponents] count]];
//}





-(void)setValue:newValue
{
    id ref=[[[MPWGenericReference alloc] initWithPathComponents:[self pathComponents] scheme:nil] autorelease];
    [baseObject at:ref put:newValue];
//s	[[self _objectToIndex:-1] setValue:newValue forKey:[self finalKey]];
}

-(void)dealloc
{
	[baseObject release];
	[super dealloc];
}



@end

@implementation NSArray(valueForPathComponent)

-valueForPathComponent:(NSString*)pathComponent
{
	if ( isdigit( [pathComponent characterAtIndex:0]) ) { 
		return [self objectAtIndex:[pathComponent intValue]];
	} else {
		if ( [pathComponent hasPrefix:@"@"] ) {
			return [super valueForPathComponent:[pathComponent substringFromIndex:1]];
		} else {
			return [super valueForPathComponent:[@"@" stringByAppendingString:pathComponent]];
		}
	}
}

@end


