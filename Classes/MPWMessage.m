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
#import "MPWBoxerUnboxer.h"

@implementation MPWMessage

scalarAccessor( SEL, selector, setSelector )
idAccessor( _signature, setSignature )

static NSMutableDictionary *conversionDict;

-(NSMutableDictionary*)createConversionDict
{
    return [[@{
               @(@encode(NSPoint)): [MPWBoxerUnboxer nspointBoxer],
               @(@encode(CGPoint)): [MPWBoxerUnboxer nspointBoxer],
               @(@encode(NSSize)): [MPWBoxerUnboxer nspointBoxer],
               @(@encode(CGSize)): [MPWBoxerUnboxer nspointBoxer],
               @(@encode(CGRect)): [MPWBoxerUnboxer nsrectBoxer],
               @(@encode(NSRect)): [MPWBoxerUnboxer nsrectBoxer],
               @(@encode(NSRange)): [MPWBoxerUnboxer nsrangeBoxer],
                 } mutableCopy] autorelease];
}



lazyAccessor(NSMutableDictionary,conversionDict, setConversionDict, createConversionDict )

+(void)setBoxer:(MPWBoxerUnboxer*)aBoxer forTypeString:(NSString*)typeString
{
    return [[[[self new] autorelease] conversionDict] setObject:aBoxer forKey:typeString];
}

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
//      NSLog(@"invoking: %@",NSStringFromSelector(selector));
//		NSLog(@"sig: %@",sig);
		if ( sig != nil ) {
			int i;
			invocation=[NSInvocation invocationWithMethodSignature:sig];
			[invocation setSelector:selector];//
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
                    double doubleBuffer[32];
                    float floatBuffer[32];
					id arg=args[i];
					void *argp=&arg;
					const char *type=[sig getArgumentTypeAtIndex:invocationIndex];
//					NSLog(@"argtype[%d]=%p",i,type);
//					NSLog(@"argtype[%d]=%s",i,type);
                    if ( *type == 'r') {        //  CONST prefix
                        type++;
                    }

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
							} else if (   !strcmp( type, "^{_NSRange=II}" ) || !strcmp( type, "^{_NSRange=QQ}") ) {
								argp=[arg rangePointer];
								break;
							}
						case '{':
                        {
                            NSLog(@"type = '%s' conversionDict = %@",type,[self conversionDict]);
                            MPWBoxerUnboxer *boxer=[[self conversionDict] objectForKey:@(type)];
                            NSLog(@"boxer: %@",boxer);
                            if ( boxer ) {
                                [boxer unboxObject:arg intoBuffer:buffer maxBytes:128];
                                argp=buffer;
                                break;
#if 0
                            } else if ( !strcmp(type,"{?=II}") ||  !strcmp( type, "{_NSRange=II}" )||  !strcmp( type, "{_NSRange=QQ}" )) {
								rangeArg = [arg asNSRange];
								argp=&rangeArg;
								break;
#endif
                            } else if (  !strcmp( type, "{CATransform3D=dddddddddddddddd}")  ) {
                                MPWRealArray *array=arg;
                                for (int i=0;i<16;i++) {
                                    doubleBuffer[i]=[array realAtIndex:i];
                                }
                                argp=array;
                                break;
                            } else if (  !strcmp( type, "{CATransform3D=ffffffffffffffff}")  ) {
                                MPWRealArray *array=arg;
                                for (int i=0;i<16;i++) {
                                    floatBuffer[i]=[array realAtIndex:i];
                                }
                                argp=array;
                                break;
							} else if (  !strcmp( type, "{_NSSize=ff}" ) || !strcmp( type, "{CGSize=ff}") ||  !strcmp( type, "{CGSize=dd}" ) ) {
								sizeArg = [arg asSize];
								argp=&sizeArg;
								break;
							}  if (   !strcmp( type, "{?=ffff}" ) || !strcmp( type, "{_NSRect={_NSPoint=ff}{_NSSize=ff}}" )||
									  !strcmp( type, "{CGRect={CGPoint=ff}{CGSize=ff}}") ||
                                              !strcmp( type, "{CGRect={CGPoint=dd}{CGSize=dd}}"  )) {
								rectArg = [arg rect];
								argp=&rectArg;
								break;
							}
                                }
						default:
							NSLog(@"default conversion for arg: %@/%@ to %@",arg,[arg class],NSStringFromSelector(selector));
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
        if ( *returnType == 'r') {      // CONST prefix
            returnType++;
        }
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
            {
                NSLog(@"type = '%s' conversionDict = %@",returnType,[self conversionDict]);
                MPWBoxerUnboxer *boxer=[[self conversionDict] objectForKey:@(returnType)];
                NSLog(@"boxer: %@",boxer);
                
                if ( boxer ) {
                    returnValue=[boxer boxedObjectForBuffer:returnBuffer maxBytes:32];
                    break;
#if 0
                } else if ( !strcmp( returnType, @encode(NSRange) )) {
					NSRange rangeVal = *(NSRange*)returnBuffer;
					returnValue=[MPWInterval intervalFromInt:rangeVal.location toInt:rangeVal.location+rangeVal.length-1];
					break;
#endif
				} else if (  !strcmp( returnType, "{_NSSize=ff}" )) {
					NSSize sizeVal = *(NSSize*)returnBuffer;
					returnValue=[MPWPoint pointWithNSSize:sizeVal];
					break;
				} else if (  !strcmp( returnType, "{CGSize=dd}") || !strcmp( returnType, "{CGSize=ff}" )  ) {
					NSSize sizeVal = *(NSSize*)returnBuffer;
					returnValue=[MPWPoint pointWithNSSize:sizeVal];
					break;
				} else if (  !strcmp( returnType, "{CATransform3D=dddddddddddddddd}")  ) {
                    double *ptr=(double*)returnBuffer;
                    MPWRealArray *array=[MPWRealArray arrayWithCapacity:16];
                    for (int i=0;i<16;i++) {
                        [array addReal:ptr[i]];
                    }
                    returnValue=array;
					break;
				} else  if ( !strcmp( returnType, "{?={?=ff}{?=ff}}" ) || !strcmp( returnType, "{_NSRect={_NSPoint=ff}{_NSSize=ff}}" ) ||
                        !strcmp( returnType, "{CGRect={CGPoint=ff}{CGSize=ff}}" )  || 
                        !strcmp( returnType, "{CGRect={CGPoint=dd}{CGSize=dd}}" ) ) {
					NSRect rectVal = *(NSRect*)returnBuffer;
					returnValue=[[[MPWRect alloc] initWithRect:rectVal] autorelease];
					break;
				}  
				
                }
			default:
				returnValue=[NSValue valueWithBytes:returnBuffer objCType:returnType];
				NSLog(@"couldn't convert return value of %@: %s, punting with:%@!",NSStringFromSelector(selector), returnType,returnValue);
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
        NSLog(@"**** doesNotUnderstand:  %@/%p  does not understand %@",[msgReceiver class],msgReceiver,NSStringFromSelector(selector));
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

+(NSRange)__nsrangeTester
{
    return NSMakeRange(3, 42);
}

+(NSPoint)__nspointTester
{
    return NSMakePoint(3.12, 23.23);
}

+(NSRect)__nsrectTester
{
    return NSMakeRect(12,42.2, 13,9);
}

+(void)testAppendingString
{
    MPWMessage* msg=[MPWMessage messageWithSelector:@selector(stringByAppendingString:)];
    IDEXPECT( [msg sendTo:@"prefix" withArguments:[NSArray arrayWithObject:@"suffix"]],@"prefixsuffix", @"stringByAppendingString:");
}

+(void)testNSRangeReturn
{
    MPWMessage* msg=[MPWMessage messageWithSelector:@selector(__nsrangeTester)];
    id result = [msg sendTo:self withArguments:nil ];
    IDEXPECT(result, [MPWInterval intervalFrom:@(3) to:@(44)], @"nsrange to interval");
}

+(void)testPointReturn
{
    MPWMessage* msg=[MPWMessage messageWithSelector:@selector(__nspointTester)];
    id result = [msg sendTo:self withArguments:nil ];
    FLOATEXPECTTOLERANCE([result x], 3.12, 0.000001, @"x");
    FLOATEXPECTTOLERANCE([result y], 23.23, 0.000001, @"y");
}

+(void)testRectReturn
{
    MPWMessage* msg=[MPWMessage messageWithSelector:@selector(__nsrectTester)];
    id result = [msg sendTo:self withArguments:nil ];
    FLOATEXPECTTOLERANCE([result x], 12, 0.000001, @"x");
    FLOATEXPECTTOLERANCE([result y], 42.2 ,0.000001, @"y");
    FLOATEXPECTTOLERANCE([result width], 13, 0.000001, @"w");
    FLOATEXPECTTOLERANCE([result height], 9 ,0.000001, @"h");
}

+testSelectors
{
    return [NSArray arrayWithObjects:
        @"test3plus4",
            @"testAppendingString",
            @"testNSRangeReturn",
            @"testPointReturn",
            @"testRectReturn",
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
