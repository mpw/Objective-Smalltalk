#import <Foundation/Foundation.h>


@interface Concatter : NSObject {}
-concat:a and:b;
@end

int main(int argc, char *argv[] ) {
   id concatter = [Concatter new];
   id s1=@"Hello ";
   id s2=@"World!";
   NSLog(@"result: %@",[concatter concat:s1 and:s2]);
   return 0;
}
