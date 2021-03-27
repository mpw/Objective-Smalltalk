//
//  MPWMessage.m
//  MPWTalk
//
//  Created by Marcel Weiher on 11/22/04.
//  Copyright 2004 Marcel Weiher. All rights reserved.
//

#import "MPWMessage.h"
#import <MPWFoundation/MPWInterval.h>
#import "MPWFastMessage.h"
#import <MPWFoundation/AccessorMacros.h>
#import "MPWBoxerUnboxer+MPWBoxingAdditions.h"

@implementation MPWMessage

scalarAccessor( SEL, selector, setSelector )
idAccessor( _signature, setSignature )


-(MPWBoxerUnboxer*)converterForType:(const char*)typeString
{
    return [MPWBoxerUnboxer converterForType:typeString];
}


-initWithSelector:(SEL)aSelector 
{
	self=[super init];
	[self setSelector:aSelector];
	return self;
}

+getFastMessageForSelector:(SEL)aSelector andSignature:(NSMethodSignature*)sig
{
#if 1
	int argCount = [sig numberOfArguments]-2;
	char typestring[ argCount+2 ];
	BOOL allIds;
	int i;
    MPWFastMessage *message=nil;
	typestring[0]=*[sig methodReturnType];
	allIds=(typestring[0]=='@');
	for (i=0;i<argCount;i++) {
		typestring[i+1]=*[sig getArgumentTypeAtIndex:i+2];
		if (typestring[i+1] != '@' ) {
			allIds=NO;
            break;
		}
	}
	typestring[argCount+1]=0;
	if (  allIds ) {
		message = [MPWFastMessage messageWithSelector:aSelector typestring:typestring];
	}
    return message;
#else
    return nil;
#endif
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
//		char charVal;
		int intVal;
		short shortVal;
		float floatVal;
		double doubleVal;
		long long longLongVal;
		NSMethodSignature* sig=[self signatureForTarget:msgReceiver];
//      NSLog(@"invoking: %@",NSStringFromSelector(selector));
		if ( sig != nil ) {
			int i;
			invocation=[NSInvocation invocationWithMethodSignature:sig];
			[invocation setSelector:selector];//
//			NSLog(@" ## args count: %d, sig numberOfArguments-2:%d",argCount,[sig numberOfArguments]-2 );
            
            // FIXME:   when I add a block as a method to a class, this become the inequality now used
            //          should be equal (and used to check that) -> also: should raise if test fails
			if ( argCount <= [sig numberOfArguments]-2 ) {
				for (i=0;i<argCount;i++) {
					int invocationIndex=i+2;
                    SEL selArg;
					char buffer[128];
                    double doubleBuffer[32];
                    float floatBuffer[32];
					id arg=args[i];
					void *argp=&arg;
					const char *type=[sig getArgumentTypeAtIndex:invocationIndex];
//					NSLog(@"## argtype[%d]=%p",i,type);
//					NSLog(@"## argtype[%d]=%s",i,type);
//                    NSLog(@"## arg: %@",arg);
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
							if ( [arg respondsToSelector:@selector(isNotNil)] &&  ![arg isNotNil] ) {
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
                        case 'b':
                        case 'B':
                        case 'c':
                        case 'C':
							longLongVal=[arg longLongValue];
							argp=&longLongVal;
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
                            MPWBoxerUnboxer *boxer=[self converterForType:type];
                            if ( boxer ) {
                                [boxer unboxObject:arg intoBuffer:buffer maxBytes:128];
                                argp=buffer;
                                break;
                            } else if (  !strcmp( type, "{CATransform3D=dddddddddddddddd}")  ) {
                                MPWRealArray *array=arg;
                                for (int realIndex=0;realIndex<16;realIndex++) {
                                    doubleBuffer[realIndex]=[array realAtIndex:realIndex];
                                }
                                argp=array;
                                break;
                            } else if (  !strcmp( type, "{CATransform3D=ffffffffffffffff}")  ) {
                                MPWRealArray *array=arg;
                                for (int realIndex=0;realIndex<16;realIndex++) {
                                    floatBuffer[realIndex]=[array realAtIndex:realIndex];
                                }
                                argp=array;
                                break;
							}
                                }
						default:
//							NSLog(@"default conversion for arg: %@/%@ to %@",arg,[arg class],NSStringFromSelector(selector));
							if ( [arg respondsToSelector:@selector(objCType)] ) {
								if ( !strcmp( type, [arg objCType] )) {
									[arg getValue:buffer];
									argp=buffer;
								} else {
//									NSLog(@"couldn't convert NSValue with %s to %s",[arg objCType],type);
								}
								break;
							}
//							NSLog(@"couldn't convert argument type: '%s'",type);
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
	unsigned char returnBuffer[256];
	const char *returnType=[_signature methodReturnType];
	
	if ( returnType!=NULL &&  *returnType != 'v' ) {
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
				intVal=*(char*)returnBuffer;
                returnValue =[NSNumber numberWithBool:intVal];
                break;
			case 'B':
				intVal=*(_Bool*)returnBuffer;
                returnValue =[NSNumber numberWithBool:intVal];
                break;
            
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
                MPWBoxerUnboxer *boxer=[self converterForType:returnType];
                if ( boxer ) {
                    returnValue=[boxer boxedObjectForBuffer:returnBuffer maxBytes:sizeof returnBuffer];
                    break;
                } else {
                    NSLog(@"couldn't get boxer/unboxer for %s",returnType);
                }
				
            }
			default:
				returnValue=[NSValue valueWithBytes:returnBuffer objCType:returnType];
//				NSLog(@"couldn't convert return value of %@: %s, punting with:%@!",NSStringFromSelector(selector), returnType,returnValue);
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
	long argCount=[args count];
	id argbuffer[ MAX(5,argCount)];
	[args getObjects:argbuffer range:NSMakeRange( 0,argCount)];
	return [self sendTo:msgReceiver withArguments:argbuffer count:(int)argCount];
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


+(MPWInterval*)__nsrangeArgTester:(NSRange)hi
{
    return [MPWInterval intervalFromInt:hi.location toInt:hi.location+hi.length-1];;
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

+(void)testNSRangeArgument
{
    NSString *tester=@"Hello World!";
    MPWInterval *trivial=[MPWInterval intervalFromInt:1 toInt:10];
    MPWInterval *result=[[MPWMessage messageWithSelector:@selector(__nsrangeArgTester:)] sendTo:self withArguments:@[ trivial ]];
    
    IDEXPECT(result, trivial, @"trival");
    
    MPWMessage* msg=[MPWMessage messageWithSelector:@selector(substringWithRange:)];
    NSString* substringresult = [msg sendTo:tester withArguments:@[ [MPWInterval intervalFromInt:6 toInt:10] ]];
    
    IDEXPECT(substringresult, @"World", @"interval to nsrange");
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
            @"testNSRangeArgument",
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
