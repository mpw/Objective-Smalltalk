
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


-(void)at:address put:value
{
	if ([value intValue]) {
		 bcm2835_gpio_write(PIN, HIGH);
	} else {
         bcm2835_gpio_write(PIN, LOW);
	}
}


@end
