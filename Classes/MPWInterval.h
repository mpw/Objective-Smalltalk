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
	long	step;
	Class numberClass;
}

scalarAccessor_h( long, from, setFrom )
scalarAccessor_h( long, to, setTo )
scalarAccessor_h( long, step, setStep )

+intervalFromInt:(long)newFrom toInt:(long)newTo;
+intervalFrom:newFrom to:newTo step:newStep;

+intervalFrom:newFrom to:newTo;
-initFromInt:(long)newFrom toInt:(long)newTo;
-initFrom:newFrom to:newTo;
-objectEnumerator;
-(NSRange)asNSRange;
-(NSRange)rangeValue;
-(NSRangePointer)rangePointer;
-(void)do:aBlock;


@end
