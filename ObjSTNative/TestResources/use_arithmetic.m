#import <Foundation/Foundation.h>


@interface ArithmeticTester : NSObject {}
-(NSNumber*)arithmeticTest;
@end

int main(int argc, char *argv[] ) {
   ArithmeticTester* a = [ArithmeticTester new];
   printf("a=%ld\n",[[a arithmeticTest] longValue]);
   return 0;
}
