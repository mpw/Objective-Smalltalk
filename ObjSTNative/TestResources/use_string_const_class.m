#import <Foundation/Foundation.h>


@interface StringTest : NSObject {}
-(NSString*)stringAnswer;
@end



int main(int argc, char *argv[] ) {
   id a = [StringTest new];
   NSLog(@"will get answer");
   NSString* answer = [a stringAnswer];
   NSLog(@"did get answer %p",answer);
   NSLog(@"class of constring string %p",[@"asdasdasdasdasd" class]);
   NSLog(@"class of answer %p",[answer class]);
   NSLog(@"answer: '%@'",answer);
   NSLog(@"length of answwer: %ld",answer.length);
   return 0;
}
