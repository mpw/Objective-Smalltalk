
#import "MPWGPIOPin.h"
#import "MPWBCMStore.h"


@implementation MPWGPIOPin
{
	int pin;
}



CONVENIENCEANDINIT( binding, WithReference:(MPWGenericReference*)ref inStore:(MPWBCMStore*)aStore)
{
	if( self=[super initWithReference:ref inStore:aStore]) {
		NSArray *pathComponents=[ref relativePathComponents];
		pin=[pathComponents.lastObject intValue];
	}
	
	return self;
	
}

-(int)pin
{
	return pin;
}


-(void)setIntValue:(int)newValue
{
	return [(MPWBCMStore*)(self.store) writePin:pin value:newValue];
}

-(int)intValue
{
	return [(MPWBCMStore*)(self.store) readPin:pin];
}

-value  { return @([self intValue]); }
-(void)setValue:newValue { [self setIntValue:[newValue intValue]]; }


@end
