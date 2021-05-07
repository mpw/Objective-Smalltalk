#!env raspish
blinker ← #Blinker{ #seconds: 1 }. 
blinker → ref:gpio:17. 
blinker run.
