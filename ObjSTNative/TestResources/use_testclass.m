#import <Foundation/Foundation.h>


@interface TestClass : NSObject
{}
@end

int main(int argc, char *argv[] ) {
   id a = [TestClass new];
   printf("a=%s\n",[[a description] UTF8String]); 
   return 0;
}
