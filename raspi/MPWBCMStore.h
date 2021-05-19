#import <MPWFoundation/MPWFoundation.h>

@interface MPWBCMStore:MPWAbstractStore

-(void)writePin:(int)pin value:(int)value;
-(int)readPin:(int)pin;

@end
