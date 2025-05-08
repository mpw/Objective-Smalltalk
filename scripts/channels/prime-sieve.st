#!env st

class filterdiv : MPWFilter {
   var divisor.
   -<void>writeObject:aNumber {
       ((aNumber mod: this:divisor ) = 0 ) ifFalse: {
	 ^aNumber.
       }. 
   }
}.
f4 ← #filterdiv{ divisor: 4 }.
f4 → #MPWPrintLiner{} → stdout.
f4 do ! (1 to: 20) each .
stdout println:''.
