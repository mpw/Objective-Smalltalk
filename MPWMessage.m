//
//  MPWMessage.m
//  MPWTalk
//
//  Created by Marcel Weiher on 11/22/04.
//  Copyright 2004 Marcel Weiher. All rights reserved.
//

#import "MPWMessage.h"
#import "MPWInterval.h"
#import "MPWFastMessage.h"
#import <MPWFoundation/NSNil.h>

@implementation MPWMessage

scalarAccessor( SEL, selector, setSelector )
idAccessor( _signature, setSignature )

-initWithSelector:(SEL)aSelector 
{
	self=[super init];
	[self setSelector:aSelector];
	return self;
}

+getFastMessageForSelector:(SEL)aSelector andSignature:(NSMethodSignature*)sig
{
	int argCount = [sig numberOfArguments]-2;
	char typestring[ argCount+2 ];
	BOOL allIds;
	int i;
	typestring[0]=*[sig methodReturnType];
	allIds=(typestring[0]=='@');
	for (i=0;i<argCount;i++) {
		typestring[i+1]=*[sig getArgumentTypeAtIndex:i+2];
		if (typestring[i+1] != '@' ) {
			allIds=NO;
		}
	}
	typestring[argCount+1]=0;
	if ( NO && allIds ) {
		return [MPWFastMessage messageWithSelector:aSelector typestring:typestring];
	}
	return nil;
}

+messageWithSelector:(SEL)aSelector initialReceiver:msgReceiver
{
	NSMethodSignature* signature = [msgReceiver methodSignatureForSelector:aSelector];
	id message=nil;
//	NSLog(@"initial receiver: %@ selector: %@ signature: %@",msgReceiver,NSStringFromSelector(aSelector),signature);
	if ( signature ) {
		message = [self getFastMessageForSelector:aSelector andSignature:signature];
	}
	if ( !message ) {
		message = [[[self alloc] initWithSelector:aSelector ] autorelease];
		[message setSignature:signature];
	}
	return message;
}

+messageWithSelector:(SEL)aSelector 
{
	return [self messageWithSelector:aSelector initialReceiver:nil];
}

-signatureForTarget:msgReceiver
{
	if ( !_signature  ) {
		[self setSignature:[msgReceiver methodSignatureForSelector:selector]];
	}
	return _signature;
}

-(NSInvocation*)invocationWithReceiver:msgReceiver args:(id*)args count:(int)argCount
{
	NSInvocation* invocation=nil;
	if ( selector != (SEL)nil ) {
		char charVal;
		int intVal;
		short shortVal;
		float floatVal;
		double doubleVal;
		long long longLongVal;
		NSMethodSignature* sig=[self signatureForTarget:msgReceiver];
//		NSLog(@"sig: %@",sig);
		if ( sig != nil ) {
			int i;
			invocation=[NSInvocation invocationWithMethodSignature:sig];
			[invocation setSelector:selector];
//			NSLog(@"args count: %d, sig numberOfArguments-2:%d",[args count],[sig numberOfArguments]-2 );
			if ( argCount == [sig numberOfArguments]-2 ) {
				for (i=0;i<argCount;i++) {
					int invocationIndex=i+2;
					NSRange rangeArg;
					NSPoint pointArg;
					NSSize sizeArg;
					NSRect rectArg;
                    SEL selArg;
					char buffer[128];
					id arg=args[i];
					void *argp=&arg;
					const char *type=[sig getArgumentTypeAtIndex:invocationIndex];
//					NSLog(@"argtype[%d]=%s",i,type);
					switch (*type) {
						case ':':
                            selArg = NSSelectorFromString( [arg stringValue] );
                            argp=&selArg;
                            break;
						case '#':	//	treat classes like objects
						case '@':
//							NSLog(@"arg: %@",arg);
							if ( ![arg isNotNil] ) {
//								NSLog(@"arg is nil!");
								arg = nil;
							}
							break;
						case 'q':
						case 'Q':
							longLongVal=[arg longLongValue];
							argp=&longLongVal;
							break;
						case 'i':
						case 'I':
							intVal=[arg intValue];
							argp=&intVal;
							break;
						case 's':
						case 'S':
							shortVal=[arg intValue];
							argp=&shortVal;
							break;
						case 'c':
						case 'C':
							charVal=[arg intValue];
							argp=&charVal;
							break;
						case 'f':
							floatVal=[arg floatValue];
							argp=&floatVal;
							break;
						case 'd':
							doubleVal=[arg doubleValue];
							argp=&doubleVal;
							break;
						case '^':
							if ( !strcmp( type, "^@" ) ) {
//								NSLog(@"detected pointer to arg, arg='%@' / %@",arg,[arg class]);
								if ( [arg isNotNil] ) {
									argp=&arg;
								} else {
									arg=nil;
									argp=&arg;
								}
								break;
							} else if (   !strcmp( type, "^{_NSRange=II}" ) ) {
								argp=[arg rangePointer];
								break;
							}
						case '{':
							if ( !strcmp(type,"{?=II}") ||  !strcmp( type, "{_NSRange=II}" )) {
								rangeArg = [arg asNSRange];
								argp=&rangeArg;
								break;
							}  else if ( !strcmp( type, "{_NSRange=QQ}" )) {
								rangeArg = [arg asNSRange];
								argp=&rangeArg;
								break;
							}  else if ( !strcmp(type,"{?=ff}") || !strcmp( type, "{_NSPoint=ff}" ) || !strcmp( type, "{CGPoint=ff}" )) {
								pointArg = [arg point];
								argp=&pointArg;
								
								break;
							} else if (  !strcmp( type, "{_NSSize=ff}" ) || !strcmp( type, "{CGSize=ff}" ) ) {
								sizeArg = [arg asSize];
								argp=&sizeArg;
								break;
							}  if (   !strcmp( type, "{?=ffff}" ) || !strcmp( type, "{_NSRect={_NSPoint=ff}{_NSSize=ff}}" )||
									  !strcmp( type, "{CGRect={CGPoint=ff}{CGSize=ff}}" )) {
								rectArg = [arg rect];
								argp=&rectArg;
								break;
							}
							
						default:
							NSLog(@"default conversion for arg: %@/%@",arg,[arg class]);
							if ( [arg respondsToSelector:@selector(objCType)] ) {
								if ( !strcmp( type, [arg objCType] )) {
									[arg getValue:buffer];
									argp=buffer;
								} else {
									NSLog(@"couldn't convert NSValue with %s to %s",[arg objCType],type);
								}
								break;
							}
							NSLog(@"couldn't convert argument type: '%s'",type);
							break;
					}
					[invocation setArgument:argp atIndex:invocationIndex];
				}
			}
		} else {
//			NSLog(@"couldn't find signature for selector: '%@' receiver of class: '%@'",NSStringFromSelector(selector),NSStringFromClass([msgReceiver class]));
		}
	}
	return invocation;
}


-invocationReturnValue:(NSInvocation*)invocation
{
	id returnValue = nil;
	int intVal;
	short shortval;
	float floatVal;
	double doubleVal;
	long long longLongVal;
	unsigned char returnBuffer[128];
	const char *returnType=[_signature methodReturnType];
	
	if ( returnType!=nil &&  *returnType != 'v' ) {
		[invocation getReturnValue:returnBuffer];
		switch (*returnType) {
			case '#':	//	treat classes like objects
			case '@':
				returnValue=*(id*)returnBuffer;
				break;
			case 's':
			case 'S':
				shortval=*(short*)returnBuffer;
				returnValue=[NSNumber numberWithShort:shortval];
				break;
			case 'i':
			case 'I':
				intVal=*(int*)returnBuffer;
				returnValue=[NSNumber numberWithInt:intVal];
				break;
			case 'q':
			case 'Q':
				longLongVal=*(long long*)returnBuffer;
				returnValue=[NSNumber numberWithLongLong:longLongVal];
				break;
			case 'c':
			case 'C':
				intVal=*(char*)returnBuffer;
				returnValue=[NSNumber numberWithInt:intVal];
				break;
			case 'f':
				floatVal=*(float*)returnBuffer;
				returnValue=[NSNumber numberWithFloat:floatVal];
				break;
			case 'd':
				doubleVal=*(double*)returnBuffer;
				returnValue=[NSNumber numberWithDouble:doubleVal];
				break;
			case '{':
				if ( !strcmp( returnType, "{?=II}" ) ||  !strcmp( returnType, "{_NSRange=II}" )) {
					NSRange rangeVal = *(NSRange*)returnBuffer;
					returnValue=[MPWInterval intervalFromInt:rangeVal.location toInt:rangeVal.location+rangeVal.length-1];
					break;
				} else if ( !strcmp( returnType, "{?=ff}" ) || !strcmp( returnType, "{_NSPoint=ff}" )) {
					NSPoint pointVal = *(NSPoint*)returnBuffer;
					returnValue=[MPWPoint pointWithNSPoint:pointVal];
					break;
				} else if ( !strcmp( returnType, "{?=dd}" ) || !strcmp( returnType, "{CGPoint=dd}" )) {
					NSPoint pointVal = *(NSPoint*)returnBuffer;
					returnValue=[MPWPoint pointWithNSPoint:pointVal];
					break;
				} else if (  !strcmp( returnType, "{_NSSize=ff}" )) {
					NSSize sizeVal = *(NSSize*)returnBuffer;
					returnValue=[MPWPoint pointWithNSSize:sizeVal];
					break;
				} else if (  !strcmp( returnType, "{CGSize=dd}" )  ) {
					NSSize sizeVal = *(NSSize*)returnBuffer;
					returnValue=[MPWPoint pointWithNSSize:sizeVal];
					break;
				}   if ( !strcmp( returnType, "{?={?=ff}{?=ff}}" ) || !strcmp( returnType, "{_NSRect={_NSPoint=ff}{_NSSize=ff}}" ) || 
						   !strcmp( returnType, "{CGRect={CGPoint=ff}{CGSize=ff}}" ) ) {
					NSRect rectVal = *(NSRect*)returnBuffer;
					returnValue=[[[MPWRect alloc] initWithRect:rectVal] autorelease];
					break;
				}  
				
				
			default:
				returnValue=[NSValue valueWithBytes:returnBuffer objCType:returnType];
				NSLog(@"couldn't convert: %s, punting with:%@!",returnType,returnValue);
				break;
		}
	}
	return returnValue;
}


-sendTo:msgReceiver withArguments:(id*)args count:(int)argCount
{
	id returnValue = nil;
	
	NSInvocation* invocation=[self invocationWithReceiver:msgReceiver args:args count:argCount];
	if ( invocation != nil ) {
		[invocation setTarget:msgReceiver];
		[invocation invoke];
		if ( @selector(release) != selector ) {
			returnValue=[self invocationReturnValue:invocation];
		}
	} else {
		[NSException raise:@"doesNotUnderstand" format:@"receiver %@/%p does not understand: %@",[msgReceiver class],msgReceiver,NSStringFromSelector(selector)];
	}
	
    return returnValue;
	
}


-sendTo:msgReceiver withArguments:args
{
	int argCount=[args count];
	id argbuffer[ MAX(5,argCount)];
	[args getObjects:argbuffer range:NSMakeRange( 0,argCount)];
	return [self sendTo:msgReceiver withArguments:argbuffer count:argCount];
}



-(void)dealloc
{
	[super dealloc];
}

@end

@implementation MPWMessage(testing)

+(void)test3plus4
{
    MPWMessage* msg=[MPWMessage messageWithSelector:@selector(add:) ];
    IDEXPECT( [msg sendTo:[NSNumber numberWithInt:3] withArguments:[NSArray arrayWithObject:[NSNumber numberWithInt:4]]],[NSNumber numberWithInt:7], @"3+4 as simple message");
}
+(void)testAppendingString
{
    MPWMessage* msg=[MPWMessage messageWithSelector:@selector(stringByAppendingString:)];
    IDEXPECT( [msg sendTo:@"prefix" withArguments:[NSArray arrayWithObject:@"suffix"]],@"prefixsuffix", @"stringByAppendingString:");
}

+testSelectors
{
    return [NSArray arrayWithObjects:
        @"test3plus4",
        @"testAppendingString",
        nil];
}

@end


@implementation NSObject(receiveMessage)

-receiveMessage:(MPWMessage*)aMessage withArguments:(id*)args count:(int)argCount
{
	return [aMessage sendTo:self withArguments:args count:argCount];
}

@end

@implementation NSProxy(receiveMessage)

-receiveMessage:(MPWMessage*)aMessage withArguments:(id*)args count:(int)argCount
{
	return [aMessage sendTo:self withArguments:args count:argCount];
}

@end
