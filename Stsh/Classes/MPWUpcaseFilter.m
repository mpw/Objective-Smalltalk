//
//  MPWUpcaseFilter.m
//  MPWShellScriptKit
//
//  Created by Marcel Weiher on 2/2/07.
//  Copyright 2007 Marcel Weiher. All rights reserved.
//

#import "MPWUpcaseFilter.h"


@implementation MPWUpcaseFilter

-(void)writeNSObject:anObject
{
	[target writeObject:[[anObject stringValue] uppercaseString]];
}

-with:arg
{
	return self;
}

@end


@implementation MPWUpcaseFilter(testing)

+(void)testbasicupcasing
{
	id results = [self process:@"somestring"];
	INTEXPECT( [results count], 1, @"elements in result array" );
	IDEXPECT( [results lastObject], @"SOMESTRING" ,@"result" );
}


+testSelectors
{
	return [NSArray arrayWithObjects:
		@"testbasicupcasing",
		nil];
}

@end