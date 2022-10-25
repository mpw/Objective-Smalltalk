#import <Foundation/Foundation.h>


@interface TestClass : NSObject {}
-(long)method;
@end

int main(int argc, char *argv[] ) {
   id a = [TestClass new];
   printf("a=%ld\n",[a method]);
   return 0;
}
