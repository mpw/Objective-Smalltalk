//
//  MPWEnvScheme.m
//  MPWShellScriptKit
//
//  Created by Marcel Weiher on 11/25/10.
//  Copyright 2010 Marcel Weiher. All rights reserved.
//

#import "MPWEnvScheme.h"
#import "MPWGenericBinding.h"

@implementation MPWEnvScheme

-(const char*)cstringValueOfBinding:aBinding
{
	return getenv([[aBinding name] UTF8String]);
}



-(BOOL)isBoundBinding:aBinding
{
	return [self cstringValueOfBinding:aBinding] != NULL;
}

-valueForBinding:aBinding
{
	const char *val=[self cstringValueOfBinding:aBinding];
	if ( val ) {
		return [NSString stringWithUTF8String:val];
	} else {
		return nil;
	}
}

-(void)setValue:newValue forBinding:aBinding
{
	if ( [newValue isKindOfClass:[MPWBinding class]] ) {
		newValue=[newValue value];
	}
	newValue=[newValue stringValue];
	if ( newValue  ) {
		setenv( [[aBinding name] UTF8String],[newValue UTF8String], 1 );
	} else {
		unsetenv([[aBinding name] UTF8String]);
	}
}


@end

#import "MPWStCompiler.h"

@implementation MPWEnvScheme(testing)

+(void)testEnvGetAndPut
{
//	EXPECTNIL([MPWStCompiler evaluate:@"env:myvar"] , @"myvar not in env");			   
	putenv("myvar=hi");
	IDEXPECT([MPWStCompiler evaluate:@"env:myvar"],@"hi",@"env:myvar");
	putenv("myvar=hi2");
	IDEXPECT([MPWStCompiler evaluate:@"env:myvar"],@"hi2",@"env:myvar");
	[MPWStCompiler evaluate:@"env:myvar := 42"];
	IDEXPECT( [NSString stringWithUTF8String:getenv("myvar")], @"42", @"getenv after env:myvar := 42");
	[MPWStCompiler evaluate:@"env:myvar := 44"];
	IDEXPECT( [NSString stringWithUTF8String:getenv("myvar")], @"44", @"getenv after env:myvar := 42");
}

+(void)testEnvironmentIsInherited
{
	[MPWStCompiler evaluate:@"env:myvar := 900"];
	FILE *fin = popen("/bin/echo -n $myvar", "r");
	NSString *echoResult=@"Did not read at all";
	if ( fin ) {
		char buffer[90]="";
		fgets(buffer, 20, fin);
		pclose(fin);
		echoResult=[NSString stringWithUTF8String:buffer];
	}
	IDEXPECT( echoResult, @"900", @"inherited var");
}

+testSelectors
{
	return [NSArray arrayWithObjects:
			@"testEnvGetAndPut",
			@"testEnvironmentIsInherited",
			nil];
}

@end

