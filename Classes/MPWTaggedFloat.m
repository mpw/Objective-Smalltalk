//
//  MPWTaggedFloat.m
//  MPWTalk
//
//  Created by Marcel Weiher on 7/18/12.
//
//

#import "MPWTaggedFloat.h"
#include <dlfcn.h>
#include <objc/runtime.h>
#include <objc/message.h>
#import "MPWFastMessage.h"

@implementation MPWTaggedFloat

static int myTag=3;

static inline float ptr2float( id px ) {
    unsigned long x=((long long)px)>>8;
    float *pf=(float*)(&x);
    return *pf; 
}

static inline id float2ptr( float fx ) {
    unsigned int *pfx=(unsigned int*)&fx;
    unsigned int *ifx=(unsigned int*)pfx;
    unsigned long long i=((unsigned long long)*ifx << 8LL) | myTag; 
    return (id)i;
}

static inline float floatValue( id ptr )
{
    if ( ((long long)ptr & 0xff) == myTag ) {
        return ptr2float(ptr);
    } else {
        return [ptr floatValue];
    }
}


static inline id taggedMul( id x1, id x2 )
{
    return float2ptr( floatValue(x1) * floatValue(x2));
}

static inline id taggedAdd( id x1, id x2 )
{
    return float2ptr( floatValue(x1) + floatValue(x2));
}

+(BOOL)isBlock
{
    return NO;
}


-(BOOL)isBlock
{
    return NO;
}

+methodSignatureForSelector:(SEL)sel
{
//    NSLog(@"+methodSignatureForSelector: %@",NSStringFromSelector(sel));
    if ( sel==@selector(float:)) {
        return [NSMethodSignature signatureWithObjCTypes:"@@:f"];
    }
    return [NSMethodSignature signatureWithObjCTypes:"@@:@"];
}

-methodSignatureForSelector:(SEL)sel
{
//    NSLog(@"-methodSignatureForSelector: %@",NSStringFromSelector(sel));
    if ( sel==@selector(floatValue)) {
        return [NSMethodSignature signatureWithObjCTypes:"f@:"];
    }
    return [NSMethodSignature signatureWithObjCTypes:"@@:@"];
}

-executeInShell:aShell
{
    return self;
}

-retain
{
    return self;
}

-stringValue
{
    return [NSString stringWithFormat:@"%g",[self floatValue]];
}

-(void)writeOnByteStream:aStream
{
    [aStream writeObject:[self stringValue]];
}

+stringValue
{
    return NSStringFromClass(self);
}

+description
{
    return [self stringValue];
}

-(oneway void)release {}
-autorelease{ return self; }

+float:(float)x
{
    return float2ptr( x );
}

-(float)floatValue
{
    return ptr2float(self);
}

#define BINARYOP( name, op )  -name:other { return float2ptr( ptr2float(self) op floatValue(other)); }

BINARYOP(mul, *)
BINARYOP(add, +)
BINARYOP(sub, -)
BINARYOP(div, /)


-(void)forwardInvocation:anInvocation
{
    id nilValue=nil;
    NSLog(@"%@ does not respond to -%@",[self class],NSStringFromSelector([anInvocation selector]));
    [anInvocation setReturnValue:&nilValue];
}

-(BOOL)respondsToSelector:(SEL)sel
{
    NSLog(@"-respondsToSelector: %@",NSStringFromSelector(sel));
    return NO;
}

+(BOOL)respondsToSelector:(SEL)sel
{
    NSLog(@"+respondsToSelector: %@",NSStringFromSelector(sel));
    return (sel == @selector(install)) ||
        (sel==@selector(float:)) ||
        (sel==@selector(class));
}

+isNotNil { return YES; }
-isNotNil { return YES; }

-(BOOL)isKindOfClass:(Class)aClass
{
    return aClass == object_getClass(self);
}

-performSelector:(SEL)selector withObject:anObject
{
    return objc_msgSend( self, selector, anObject);
}

-description
{
    return [NSString stringWithFormat:@"tagged float %p - %g",self,ptr2float(self)];
}

-descriptionWithLocale:aLocale
{
    return [self description];
}

+(void)install
{
    char *vtable=dlsym( RTLD_DEFAULT, "objc_ehtype_vtable");
    Class *table=(Class*)(vtable+1672);
    if ( vtable && table) {
#if 0
        for (int i=0;i<16;i++ ) {
            NSLog(@"tagged[%d]=%@",i,table[i]);
        }
#endif
        if ( table[myTag] ) {
            NSLog(@"tagged_table[%d] occupied with %p, aborting",myTag,table[myTag]);
            return ;
        }
        table[myTag]=NSClassFromString(@"MPWTaggedFloat");
    } else {
        NSLog(@"tagged class table not found");
        return ;
    }
    
}

-class
{
    return object_getClass(self);
}

+class
{
    return self;
}

-receiveMessage:aMessage withArguments:(id*)args count:(int)argCount
{
	return [aMessage sendTo:self withArguments:args count:argCount];
}

@end
