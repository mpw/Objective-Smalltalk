#!env st

class filterdiv : MPWFilter {
   var divisor.
   -<void>writeObject:aNumber sender:s {
       ((aNumber mod: this:divisor ) = 0 ) ifFalse: {
	 ^aNumber.
       }. 
   }
    -description { "filter for {this:divisor} target: {this:target}". }
}.

stdout println:'did define filterdiv.'.

class sievefilter : MPWFilter {
     var currentfilter.
     var lastfilter.
     -<void>writeObject:aNumber sender:sender  {
        newfilter ← #filterdiv{ divisor: aNumber, target: this:self }.
        this:currentfilter setTarget:newfilter.
        this:currentfilter ← newfilter.
        ^aNumber. 
     }
}.

stdout println:'did define sieve.'.

s ← #sievefilter{}.
f2 ← #filterdiv{ divisor: 2, target: s }.
s setCurrentfilter: f2.
s setLastfilter: s.
f2 setTarget:s.
s → #MPWPrintLiner{} → stdout.
f2 do ! (3 to: 200) each .
stdout println:''.
