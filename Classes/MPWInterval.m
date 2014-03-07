//
//  MPWInterval.m
//  MPWTalk
//
//  Created by Marcel Weiher on 26/11/2004.
//  Copyright 2004 BBC. All rights reserved.
//

#import "MPWInterval.h"
#import "MPWBlockContext.h"
#import <MPWFoundation/MPWFoundation.h>
#import <MPWFoundation/MPWStream.h>

@interface MPWIntervalEnumerator : MPWInterval
{
    int current;
}

intAccessor_h( current, setCurrent )
-initWithInterval:(MPWInterval*)interval;
+enumeratorWithInterval:(MPWInterval*)interval;
-nextObject;


@end

@implementation MPWInterval

#define FROM	range.location

#define INTATINDEX( anIndex )   ((FROM + (anIndex))*step)
#define TO		((range.location + range.length-1))


-(int)from {  return FROM; } 
-(int)to   {  return TO; }
-(void)setFrom:(int)newFrom { range.location=newFrom; }
-(void)setTo:(int)newTo { range.length = newTo - range.location + 1; }

//scalarAccessor( int, from, setFrom )
//scalarAccessor( int, to, setTo )
intAccessor( step, _setStep )

-(void)setStep:(int)newVar
{
	if ( newVar <= 0 ) {
		@throw [NSException
				exceptionWithName:@"InvalidArgument"
				reason:[NSString stringWithFormat:@"-[%@ setStep:%d] must be >=1",[self class],newVar]
				userInfo:nil];
		
	}
	[self _setStep:newVar];
}

scalarAccessor( Class, numberClass ,setNumberClass )

+intervalFrom:newFrom to:newTo 
{
	return [[[self alloc] initFrom:newFrom to:newTo ] autorelease];
}


+intervalFrom:newFrom to:newTo step:newStep
{
	return [[[self alloc] initFrom:newFrom to:newTo step:newStep] autorelease];
}



+intervalFromInt:(int)newFrom toInt:(int)newTo step:(int)newStep
{
	return [[[self alloc] initFromInt:newFrom toInt:newTo step:newStep numberClass:[NSNumber class]] autorelease];
}

+intervalFromInt:(int)newFrom toInt:(int)newTo
{
	return [self intervalFromInt:newFrom toInt:newTo step:1];
}

-initFromInt:(int)newFrom toInt:(int)newTo step:(int)newStep numberClass:(Class)newNumberClass
{
	self=[super init];
	[self setFrom:newFrom];
	[self setTo:newTo];
	[self setStep:newStep];
	[self setNumberClass:newNumberClass];
	return self;
}

-initFromInt:(int)newFrom toInt:(int)newTo  numberClass:(Class)newNumberClass
{
	return [self initFromInt:newFrom toInt:newTo step:1 numberClass:newNumberClass];
}


-initFromInt:(int)newFrom toInt:(int)newTo
{
	return [self initFromInt:newFrom toInt:newTo numberClass:[NSNumber class]];
}



-initFrom:newFrom to:newTo step:newStep
{
	return [self initFromInt:[newFrom intValue] toInt:[newTo intValue] step:[newStep intValue] numberClass:[newFrom class]];
}

-initFrom:newFrom to:newTo
{
	return [self initFromInt:[newFrom intValue] toInt:[newTo intValue] step:1 numberClass:[newFrom class]];
}


-do:aBlock with:target
{
	int i;
	id value=nil;
	id pool=[NSAutoreleasePool new];
	for (i=FROM;i<=TO;i+=step ) {
		value = [aBlock value:[NSNumber numberWithInt:i]];
		if ( i % 100 == 0 ) {
			[pool release];
			pool=[NSAutoreleasePool new];
		}
		[target addObject:value];
	}
	[pool release];
	return target ? target : value;
}

-collect:aBlock
{
	return [self do:aBlock with:[NSMutableArray array]];
}

-do:aBlock
{
	return [self do:aBlock with:nil];
}

-(BOOL)containsInteger:(int)anInt
{
    return FROM <= anInt && anInt <= TO;
}

-(BOOL)containsObject:anObject
{
    return  [anObject respondsToSelector:@selector(intValue)] &&
            [self containsInteger:[anObject intValue]];
}

-objectEnumerator
{
    return [MPWIntervalEnumerator enumeratorWithInterval:self];
}

-each
{
    return [self objectEnumerator];
}

-(NSUInteger)count
{
    return range.length / step;
}


-(int)integerAtIndex:(NSUInteger)anIndex
{
	if ( anIndex >= [self count] ) {
		@throw [NSException
				exceptionWithName:@"RangeException"
				reason:[NSString stringWithFormat:@"-[%@ integerAtIndex:%ld] out of bounds(%ld)",[self class],(long)anIndex,(long)[self count]]
				userInfo:nil];
	}
	return INTATINDEX( anIndex );
}

-objectAtIndex:(NSUInteger)anIndex
{
	return [NSNumber numberWithInt:[self integerAtIndex:anIndex]];
}

-description 
{
	return [NSString stringWithFormat:@"<%@:%p from %d to %d>",[self class],self,[self from],[self to]];
}

-(NSRange)asNSRange {
	return range;
}

-(NSRange)rangeValue {
	return range;
}

-(NSRangePointer)rangePointer {
	return &range;
}

-(void)encodeWithCoder:aCoder
{
	int from=FROM,to=TO;
	encodeVar( aCoder, from );
	encodeVar( aCoder, to );
}

-initWithCoder:aCoder
{
	self=[super initWithCoder:aCoder];
	int from,to;
	decodeVar( aCoder, from );
	decodeVar( aCoder, to );
	[self setFrom:from];
	[self setTo:to];
	return self;
}

-(void)writeOnStream:aStream
{
    [aStream writeEnumerator:self];
}

@end

@implementation MPWInterval(testing)

+(void)testBasicInterval
{
	MPWInterval *one_to_ten=[MPWInterval intervalFromInt:1 toInt:10];
	INTEXPECT( [one_to_ten integerAtIndex:0], 1, @"first of [1-10]");
	INTEXPECT( [one_to_ten integerAtIndex:1], 2, @"second of [1-10]");
	INTEXPECT( [one_to_ten integerAtIndex:9], 10, @"last of [1-10]");
}

+(void)testIntervalRespectsRange
{
	MPWInterval *one_to_ten=[MPWInterval intervalFromInt:1 toInt:10];
	BOOL failedToRaise=NO;
	@try {
		[one_to_ten integerAtIndex:10];
		failedToRaise=YES;
	}
	@catch (NSException * e) {
	}
	EXPECTFALSE( failedToRaise, @"failedToRaise");
}

+(void)testIntervalWithStep
{
	MPWInterval *one_to_ten=[MPWInterval intervalFromInt:1 toInt:10 step:2];
	INTEXPECT( [one_to_ten count] ,5, @"count");
	INTEXPECT( [one_to_ten integerAtIndex:0], 2, @"first of [1-10]");
	INTEXPECT( [one_to_ten integerAtIndex:1], 4, @"second of [1-10]");
	INTEXPECT( [one_to_ten integerAtIndex:4], 10, @"last of [1-10]");
}


+testSelectors
{
    return [NSArray arrayWithObjects:
			@"testBasicInterval",
			@"testIntervalRespectsRange",
			@"testIntervalWithStep",
        nil];
}

@end

@implementation MPWIntervalEnumerator

intAccessor( current, setCurrent )

-initFromInt:(int)newFrom toInt:(int)newTo
{
    self=[super initFromInt:newFrom toInt:newTo];
    [self setCurrent:newFrom];
    return self;
}

-initWithInterval:(MPWInterval*)interval
{
    self=[super init];
    [self setFrom:[interval from]];
    [self setTo:[interval to]];
    [self setStep:[interval step]];
    [self setCurrent:[self from]];
    return self;
}
+enumeratorWithInterval:(MPWInterval*)interval
{
    return [[[self alloc] initWithInterval:interval] autorelease];
}
-(BOOL)isAtEnd
{
    return current > TO;
}

-nextObject
{
    id retval=nil;
    if ( ![self isAtEnd] ) {
        retval=[NSNumber numberWithInt:current];
        current+=step;
    }
    return retval;
}

-objectEnumerator
{
    return self;
}

@end

@implementation NSArray(iteration)

-do:aBlock with:target
{
	int i,max;
	id value=nil;
	for (i=0,max=[self count];i<max;i++ ) {
		value = [aBlock value:[self objectAtIndex:i]];
		[target addObject:value];
	}
	return target ? target : value;
}

-collect:aBlock
{
	return [self do:aBlock with:[NSMutableArray array]];
}

-do:aBlock
{
	return [self do:aBlock with:nil];
}


@end

