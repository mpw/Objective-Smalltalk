
#import "MPWGPIOPin.h"
#import "MPWBCMStore.h"
#include <poll.h>



@interface MPWGPIOPin()

@property (nonatomic, strong) NSFileHandle *fileHandle;

@end

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

-(void)startListening
{
	NSString *pinString=[@(pin) stringValue];
	[pinString writeToFile:@"/sys/class/gpio/export" atomically:NO];
	NSLog(@"will set up");
	[NSThread sleepForTimeInterval:0.2];
	[@"in" writeToFile:[NSString stringWithFormat:@"/sys/class/gpio/gpio%d/direction",pin] atomically:NO];
	[@"both" writeToFile:[NSString stringWithFormat:@"/sys/class/gpio/gpio%d/edge",pin] atomically:NO];
	NSString *valuePath=[NSString stringWithFormat:@"/sys/class/gpio/gpio%d/value",pin];
	NSLog(@"listen to: '%@'",valuePath);
	int fd=open([valuePath UTF8String],O_RDONLY);
	NSLog(@"fd=%d",fd);
	while (1) {
		char buffer[10];
		struct pollfd waiter= { fd, 1 << POLL_IN, 0 };
		int retval=poll( &waiter, 1, 1000000);
		read( fd, buffer, 2);
		lseek( fd, 0, SEEK_SET);
		[self.target writeObject:[self value]];
	}
}
@end
