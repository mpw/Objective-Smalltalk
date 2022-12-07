extern int fn(int (^block)(int));
int bfn(int a) { return fn( ^(int a){ return a + 3; } ); }
