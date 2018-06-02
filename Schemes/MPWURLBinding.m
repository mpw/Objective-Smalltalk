//
//  MPWURLBinding.m
//  MPWShellScriptKit
//
//  Created by Marcel Weiher on 20.1.10.
//  Copyright 2010 Marcel Weiher. All rights reserved.
//

#import "MPWURLBinding.h"
#import "MPWResource.h"
#import <MPWFoundation/MPWSocketStream.h>

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
    NSLog(@"getWithArgs:%@",inv);
    NSLog(@"sending to target: %@",target);
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
	const char *selname=sel_getName(aSelector);
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

objectAccessor(NSError, error, setError)

-get
{
	return [self _value];
}
-(BOOL)isBound
{
	return YES;
}


-getWithArgs
{
    NSLog(@"getWithArgs");
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
	NSAssert2( ([argKeys count]-1) == [args count], @"number of args not same: %p %p",argKeys,args);
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
    long i,max=[[inv methodSignature] numberOfArguments];
    for (i=2; i<max; i++) {
        id arg=nil;
        [inv getArgument:&arg atIndex:i];
        if ( !arg ) {
            NSLog(@"nil arg at %ld",i);
            arg=@"";
        }
        [args addObject:arg];
    }
    id query = [self urlWithArgsFromSelectorString:selname args:args];
    NSURL *fullURL=[NSURL URLWithString:[[[self url] stringValue] stringByAppendingString:query]];
    id result= [self.store _valueWithURL:fullURL];
    [inv setReturnValue:&result];
    return result;
}

-fileSystemValue
{
    return [NSDictionary dictionaryWithObject:[[self url] stringValue] forKey:@"URL"];
}

-(void)put:data
{
    NSMutableURLRequest *urlRequest = [NSMutableURLRequest requestWithURL:[self url]];
    [urlRequest setHTTPMethod:@"PUT"];
    
    
    [urlRequest setHTTPBody:data];
    [NSURLConnection connectionWithRequest:urlRequest delegate:self];
    if ( inPOST ) {
        [NSException raise:@"PUT in progress" format:@"PUT to %@/%@ already in progress",self,[self url]];
    }
    inPOST=YES;
    while (inPOST) {
        [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.01]];
    }
}

-(NSData*)post:data withName:(NSString*)postName
{
    NSString *boundary=@"0xKhTmLbOuNdArY";
    NSMutableURLRequest *urlRequest = [NSMutableURLRequest requestWithURL:[self url]];

    [urlRequest setHTTPMethod:@"POST"];
    
    [urlRequest setValue:[NSString stringWithFormat:@"multipart/form-data; boundary=%@", boundary] forHTTPHeaderField:@"Content-Type"];
    
    NSMutableData *postData = [NSMutableData data];
    [postData appendData:[[NSString stringWithFormat:@"--%@\r\n", boundary] dataUsingEncoding:NSUTF8StringEncoding]];
    [postData appendData:[[NSString stringWithFormat:@"Content-Disposition: form-data; name=\"%@\"; filename=\"%@\"\r\n\r\n", postName, postName] dataUsingEncoding:NSUTF8StringEncoding]];
    [postData appendData:data];
    [postData appendData:[[NSString stringWithFormat:@"\r\n--%@\r\n", boundary] dataUsingEncoding:NSUTF8StringEncoding]];
    [urlRequest setHTTPBody:postData];
    return [self resourceWithRequest:urlRequest];
}

-(NSData*)post:data
{
    return [self post:data withName:@"methods"];       // FIXME:  remove
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection
{
    inPOST=NO;
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)localError
{
    inPOST=NO;
    [self setError:localError];
}

-(void)_setValue:newValue
{
    if (newValue) {
        [self put:newValue];
    }
}

-stream
{
    return [[[MPWSocketStream alloc] initWithURL:[self url]] autorelease];
}

-(NSString *)description
{
    return [[self url] absoluteString];
}

@end


@implementation MPWURLBinding(testing)

+(void)testURLArgsFromSelectorAndArgs
{
    MPWGenericReference *ref=[MPWGenericReference referenceWithPath:@"//ajax.googleapis.com/ajax/services/language/translate" ];
    ref.schemeName=@"http";
    MPWURLBinding *binding=[self bindingWithReference:ref inStore:nil];
    
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
