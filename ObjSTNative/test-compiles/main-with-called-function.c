#include <stdio.h>

extern int fn(int);

int other(int arg)
{
   return printf("other was called with %d\n",arg);
}

int main(int argc, char *argv[]) {
   return fn(3);
}
