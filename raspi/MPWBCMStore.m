
#import "MPWBCMStore.h"
#import "MPWGPIOPin.h"
#include <bcm2835.h>

#define MINPIN 0
#define MAXPIN 32

@implementation MPWBCMStore 
{
	int modes[MAXPIN*2];
}


#define PIN RPI_GPIO_P1_11


-(instancetype)init
{
	self=[super init];
    if (!bcm2835_init()) {
      return nil;
	} 
	return self;
}

-(void)setMode:(int)mode ofPin:(int)pin
{
	if ( pin>=MINPIN && pin <MAXPIN) {
		if( modes[pin] != mode ) {
			bcm2835_gpio_fsel(pin, mode);
			modes[pin]=mode;	
		}
	}
}

-(void)writePin:(int)pin value:(int)value
{
	if ( pin>=0 && pin < MAXPIN ) {
		[self setMode:BCM2835_GPIO_FSEL_OUTP ofPin:pin];	
		bcm2835_gpio_write(pin, value);
	} else {
		[NSException raise:@"pin out of range" format:@"pin %d out of range",pin];
	}
}

-(int)readPin:(int)pin 
{
	if ( pin>=0 && pin < MAXPIN ) {
		[self setMode:BCM2835_GPIO_FSEL_INPT ofPin:pin];	
		return bcm2835_gpio_lev(pin) ? YES : NO;
	} else {
		[NSException raise:@"pin out of range" format:@"pin %d out of range",pin];
	}
	return 0;
}


-(id)at:(id <MPWReferencing>)address 
{
	NSArray<NSString*> *pathComponents=[address pathComponents];
	if ( pathComponents.count == 1 ) {
		int pinNumber = [pathComponents[0] intValue];
		return @([self readPin:pinNumber]);
	} else {
        [NSException raise:@"incorrect pin address" format:@"%@",pathComponents];
	}
	return nil;

}

-(void)at:(id <MPWReferencing>)address put:value
{
	NSArray<NSString*> *pathComponents=[address pathComponents];
	if ( pathComponents.count == 1 ) {
		int pinNumber = [pathComponents[0] intValue];
		int pinValue = [value intValue] ? HIGH : LOW;
		[self writePin:pinNumber value:pinValue];
	} else {
        [NSException raise:@"incorrect pin address" format:@"%@",pathComponents];
	}

}

-(MPWBinding*)bindingForReference:aReference inContext:aContext
{
	return [MPWGPIOPin bindingWithReference:aReference inStore:self];
}

-(void)dealloc
{
	bcm2835_close();
	[super dealloc];
}


@end
