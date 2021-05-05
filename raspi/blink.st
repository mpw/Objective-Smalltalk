#!env raspish
blinker ← MPWFixedValueSource streamWithTarget: ref:gpio:17. 
blinker setValues: #(0,1).
blinker fireEvery:1 .
NSRunLoop currentRunLoop run.
