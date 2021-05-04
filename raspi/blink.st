#!env raspish
a := MPWFixedValueSource stream.
a setValues:#( 1, 0). 
scheme:gpio := MPWBCMStore store.
pin := ref:gpio:1 
a setTarget: pin.
a fireEvery:1.
stdout println:'should start blinking, Ctrl-C to quit'.
NSRunLoop mainRunLoop run.
