#import <Foundation/Foundation.h>

@interface Hi : NSObject {}

-(NSArray*)lines:(NSString*)s;
@end

@implementation Hi

-(NSString*)onLine:(NSString*)line execute:(NSString* (^)(NSString *line))block
{
  return block(line);
}


-(NSArray*)lines:(NSString*)s 
{
    NSMutableArray *lines=[NSMutableArray array];
    [s enumerateLinesUsingBlock:^(NSString *line,  BOOL *stop){
              [lines addObject:line];
    }];
  return lines;

}
 
@end
