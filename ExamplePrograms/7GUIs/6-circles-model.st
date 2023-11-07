#!env st

class Circle {
    var center.
    var radius.
}.


class Circles {
     var circles.
     var currentRadius.
     -init {
        super init.
        self setCircles: #NSMutableArray[]. 
        self setCurrentRadius: 10.
        self.
     }
     -<void>addCircleAt: location {
           newCircle ← #Circle{ #center: location , #radius: (self currentRadius) }.
           stdout println: self currentRadius.
           newCircle setRadius: self currentRadius.
           self circles addObject: newCircle.
    }
    -<void>drawOn: aContext {
           aContext do circle: self circles each.
    }
    -description {
       count := this:circles count.
       "{count} circles". 
    }
    -count {
       this:circles count.
    }
    +testCanAddCircles {
        circles := self new.
        circles count assertEqual:0 msg:'empty after creation'.
        circles addCircleAt: (125 @ 34 ).
        circles count assertEqual:1 msg:'1 after add'.

    }
    +testSelectors { [
         'testCanAddCircle',
       ]. 

    }
}.


circles ← #Circles{}.

Circles testCanAddCircles.

