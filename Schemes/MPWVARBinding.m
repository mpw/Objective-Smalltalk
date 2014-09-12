//
//  MPWVARBinding.m
//  MPWTalk
//
//  Created by Marcel Weiher on 17.12.09.
//  Copyright 2009 Marcel Weiher. All rights reserved.
//

#import "MPWVARBinding.h"
#import "MPWInterval.h"

@implementation MPWVARBinding

objectAccessor( NSArray, pathComponents, setPathComponents )
idAccessor( baseObject, setBaseObject )


-initWithBaseObject:newBase pathComponents:(NSArray*)newPathComponents
{
	self=[super init];
	[self setPathComponents:newPathComponents];
	[self setBaseObject:newBase];
	return self;
	
}

-path
{
    return [[self pathComponents] componentsJoinedByString:@"/"];
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

-(id)_objecToIndex:(int)anIndex
{
	anIndex=MIN(anIndex, (int)[pathComponents count]);
	id result=baseObject;
	int i;
	for (i=0;i<anIndex;i++) {
		result=[result valueForPathComponent:[pathComponents objectAtIndex:i]];
	}
	return result;
				
}

-_value
{
	return [self _objecToIndex:(int)[pathComponents count]];
}

-(void)startObserving
{
    id base = [self _objecToIndex:(int)[pathComponents count]-1];
    NSString *property=[pathComponents lastObject];
//    NSLog(@"%p start observing '%@' of %@ with %@",self,property,base,[self name]);
    [base objst_addObserver:self forKey:property];
    
}

-(void)stopObserving
{
    id base = [self _objecToIndex:(int)[pathComponents count]-1];
    NSString *property=[pathComponents lastObject];
    [base removeObserver:base forKeyPath:property];
}




-(void)_setValue:newValue
{
	id target=[self _objecToIndex:(int)[pathComponents count]-1];
	[target setValue:newValue forKey:[pathComponents lastObject]];
}

-(void)dealloc
{
	[baseObject release];
	[pathComponents release];
	[super dealloc];
}



@end

@implementation NSObject(valueForPathComponent)

-valueForPathComponent:(NSString*)pathComponent
{
	return [self valueForKey:pathComponent];
}

-(void)objst_addObserver:anObserver forKey:aKey
{
    NSLog(@"%@ objst_addObserver: %@",self,anObserver);
    [self addObserver:anObserver forKeyPath:aKey options:0 context:NULL];
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


