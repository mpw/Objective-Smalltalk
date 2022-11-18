#import <MPWFoundation/MPWFoundation.h>


@interface Upcaser : MPWFilter
@end

int main(int argc, char *argv[] ) {
   id a = [Upcaser streamWithTarget:[MPWByteStream Stdout]];
   [a writeObject:@"some text"];
   return 0;
}
