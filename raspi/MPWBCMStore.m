
#import "MPWBCMStore.h"
#include <bcm2835.h>

@implementation MPWBCMStore 

#define PIN RPI_GPIO_P1_11


-(instancetype)init
{
	self=[super init];
    if (!bcm2835_init())
      return nil;
 
    // Set the pin to be an output
    bcm2835_gpio_fsel(PIN, BCM2835_GPIO_FSEL_OUTP);
	return self;
}

-(void)writePin:(int)pin value:(int)value
{
	if ( pin>=0 && pin <=31 ) {
		bcm2835_gpio_write(pin, value);
	} else {
		[NSException raise:@"pin out of range" format:@"pin %d out of range",pin];
	}
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


@end
