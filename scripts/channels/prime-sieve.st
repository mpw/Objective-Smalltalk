#!env st

filter filterdiv  {
   var divisor.
   |{ ((object mod: this:divisor ) = 0 ) ifFalse: { ^object.  }. }
}.

filter sievefilter  {
     -initWithTarget:aTarget {
	self ← super initWithTarget:aTarget.
        this:lastfilter ← self.
        this:currentfilter ← #filterdiv{ divisor: 2, target: self }.
        self.
     }
     var currentfilter.
     var lastfilter.
     -<void>addFilterForNumber:aNumber {
        newfilter ← #filterdiv{ divisor: aNumber, target: this:self }.
        this:currentfilter setTarget:newfilter.
        this:currentfilter ← newfilter.
     }
     |{  self addFilterForNumber:object.  ^object.  }
     -<void>filterTo: max {
	this:currentfilter do ! (2 to:max) each.
     }
}.


s ← #sievefilter{ target: (#MPWPrintLiner{} → stdout) }.
s filterTo:200.
