#!env st
#-<void>testCircle

class Circle {
    var center.
    var radius.
}.

extension MPWPoint {
  -<int>isEqual:other {
        self x = other x and: self y = other y.
  }
}


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
           newCircle setRadius: self currentRadius.
           self circles addObject: newCircle.
    }
    -<void>drawOn: aContext {
           aContext do circle: self circles each.
    }
    -at:anIndex { this:circles at:anIndex. }
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
	pt2 := 125@34.
        (circles at:0 ) center assertEqual:pt2 msg:'location of added circle'.
        (circles at:0 ) radius assertEqual:10  msg:'radius of added circle'.

    }
    +testSelectors { [
         'testCanAddCircles',
       ]. 

    }
}.



Circles testSelectors do: { :selector |
   Circles performSelector: selector .
}.

