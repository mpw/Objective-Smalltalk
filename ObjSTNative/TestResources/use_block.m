#import <Foundation/Foundation.h>


extern int (^global_block)(int);

int (^local_block)(int)=^(int a){  return a+12; };

int main(void) {
    int a = global_block(3);
    int b = local_block(3);
    printf("a=%d, b=%d\n",a,b);
    return 0;
}
