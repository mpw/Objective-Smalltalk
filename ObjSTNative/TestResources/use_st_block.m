#import <ObjectiveSmalltalk/ObjectiveSmalltalk.h>


extern id (^theBlock)();

int main(void) {
    [MPWBlockContext new];
    id b = [theBlock value];
    printf("b=%p\n",b);
    NSLog(@"b=%@",b);
    return 0;
}
