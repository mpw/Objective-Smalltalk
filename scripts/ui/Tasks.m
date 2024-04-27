#import <Foundation/Foundation.h>

@interface Task:NSObject{}
@property(nonatomic,strong) id id,done,title;
@end
@implementation Task

-copyWithZone:aZone
{
   return [self retain];
}

@end
