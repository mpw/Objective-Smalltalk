#!env st


filter source {
    var max.
    -<void> run {  2 to: this:max do: { :num | this:target ! num. }. }
}

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
}.


s ← #source{ max:2000 } →  (#sievefilter{} currentfilter)  → #MPWPrintLiner{} → stdout.
s run.
