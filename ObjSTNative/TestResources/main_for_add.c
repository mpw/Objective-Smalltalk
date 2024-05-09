#include <stdio.h>

extern int add(int a,int b);

int main(int argc, char *argv[] ) {
   printf("res: %d\n",add(3,4));
   return 0;
}
