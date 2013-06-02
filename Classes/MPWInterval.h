//
//  MPWInterval.h
//  MPWTalk
//
//  Created by Marcel Weiher on 26/11/2004.
//  Copyright 2004 Marcel Weiher. All rights reserved.
//

#import <MPWFoundation/MPWFoundation.h>

@interface MPWInterval : NSArray {
	NSRange range;
	int	step;
	Class numberClass;
}

scalarAccessor_h( int, from, setFrom )
scalarAccessor_h( int, to, setTo )
scalarAccessor_h( int, step, setStep )

+intervalFromInt:(int)newFrom toInt:(int)newTo;
+intervalFrom:newFrom to:newTo step:newStep;

+intervalFrom:newFrom to:newTo;
-initFromInt:(int)newFrom toInt:(int)newTo;
-initFrom:newFrom to:newTo;
-objectEnumerator;
-(NSRange)asNSRange;
-(NSRangePointer)rangePointer;
-do:aBlock;


@end
