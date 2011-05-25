//
//  MPWURLBinding.m
//  MPWShellScriptKit
//
//  Created by Marcel Weiher on 20.1.10.
//  Copyright 2010 Marcel Weiher. All rights reserved.
//

#import "MPWURLBinding.h"
#import "MPWResource.h"

@interface SayYES : NSObject
{
	id target;
}
idAccessor_h( target, setTarget )

@end

@implementation SayYES 
idAccessor( target, setTarget )

-(BOOL)respondsToSelector:(SEL)selector { return YES; }
-getWithArgs:(NSInvocation*)inv
{
	return [target getWithArgs:inv];
}
-methodSignatureForSelector:(SEL)aSelector
{
	static char *sigsByArgNum[]={
		"@@:", 
		"@@:@", 
		"@@:@@", 
		"@@:@@@", 
		"@@:@@@@", 
		"@@:@@@@@", 
		"@@:@@@@@@", 
			
	};
	char *selname=sel_getName(aSelector);
	int numargs=0;
	do {
		if ( *selname == ':' ) {
			numargs++;
		}
	} while ( *selname++ );
	return [NSMethodSignature signatureWithObjCTypes:sigsByArgNum[numargs]];
}

-(void)dealloc
{
	[target release];
	[super dealloc];
}
@end


@implementation MPWURLBinding

-error
{
	return error;
}

-get
{
	return [self value];
}

-_valueWithURL:(NSURL*)aURL
{
	NSMutableURLRequest *request=[[[NSMutableURLRequest alloc] initWithURL:aURL] autorelease];
	NSMutableDictionary *headers=[NSMutableDictionary dictionaryWithObject:@"locale=en-us" forKey:@"Cookies"];
	NSURLResponse *response=nil;
	[headers setObject:@"stsh" forKey:@"User-Agent"];
	[headers setObject:@"*/*" forKey:@"Accept"];
	[request setAllHTTPHeaderFields:headers];
	NSData *rawData = [NSURLConnection sendSynchronousRequest:request returningResponse:&response error:&error];
	MPWResource *result=[[[MPWResource alloc] init] autorelease];
	[result setSource:aURL];
	[result setRawData:rawData];
	[result setMimetype:[response MIMEType]];
	return result;
}



-getWithArgs
{
	id yes=[[[SayYES alloc] init] autorelease];
	MPWTrampoline	*trampoline=[MPWTrampoline quickTrampoline];
	[yes setTarget:self];
	[trampoline setXxxTarget:yes];
	[trampoline setXxxSelector:@selector(getWithArgs:)];
	return trampoline;
}

-urlWithArgsFromSelectorString:(NSString*)selectorString args:(NSArray*)args
{
	int i;
	NSMutableString *result=[NSMutableString string];
	NSString *separator=@"?";
	NSArray *argKeys=[selectorString componentsSeparatedByString:@":"];
	NSAssert2( ([argKeys count]-1) == [args count], @"number of args not same: %d %d",argKeys,args);
	for (  i=0;i<[args count]; i++) {
		[result appendFormat:@"%@%@=%@",separator,[argKeys objectAtIndex:i],[[args objectAtIndex:i] stringByAddingPercentEscapesUsingEncoding:
																			 NSASCIIStringEncoding]];
		separator=@"&";
	}
	return result;
}

-getWithArgs:(NSInvocation*)inv
{
	NSString *selname=NSStringFromSelector([inv selector]);
	NSMutableArray *args=[NSMutableArray array];
	int i,max=[[inv methodSignature] numberOfArguments];
	for (i=2; i<max; i++) {
		id arg=nil;
		[inv getArgument:&arg atIndex:i];
		if ( !arg ) {
			NSLog(@"nil arg at %d",i);
			arg=@"";
		}
		[args addObject:arg];
	}
	id query = [self urlWithArgsFromSelectorString:selname args:args];
	NSURL *fullURL=[NSURL URLWithString:[[[self url] stringValue] stringByAppendingString:query]];
	id result= [self _valueWithURL:fullURL];
	[inv setReturnValue:&result];
	return result;
}


@end


@implementation MPWURLBinding(testing)

+(void)testURLArgsFromSelectorAndArgs
{
	MPWURLBinding *binding=[[[self alloc] initWithPath:@"http://ajax.googleapis.com/ajax/services/language/translate"] autorelease];
	NSString *pathArgs=[binding urlWithArgsFromSelectorString:@"v:langpair:q:" 
													 args:[NSArray arrayWithObjects:@"1.0",@"en|de",@"Delete",nil]];
	IDEXPECT( pathArgs, @"?v=1.0&langpair=en%7Cde&q=Delete", @"basic path args" );
	pathArgs=[binding urlWithArgsFromSelectorString:@"v:langpair:q:" 
									  args:[NSArray arrayWithObjects:@"1.1",@"en|de",@"Delete file.",nil]];
	IDEXPECT( pathArgs, @"?v=1.1&langpair=en%7Cde&q=Delete%20file.", @"path args with space" );
}

+(NSArray*)testSelectors
{
	return [NSArray arrayWithObjects:
				@"testURLArgsFromSelectorAndArgs",
			nil];
	
}

@end
