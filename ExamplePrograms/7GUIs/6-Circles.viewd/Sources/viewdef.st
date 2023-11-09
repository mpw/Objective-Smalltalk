extension MPWCGDrawingContext {
    -circle: aCircle  {
          self arcWithCenter:aCircle center  radius:aCircle radius startDegrees:0 endDegrees:360  clockwise:false; stroke.
        self.
    }
}.

class Circle {
    var center.
    var radius.
    -contains:aPoint {
           (self center distance: aPoint ) < self radius.
    }
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
    -atIndex:anIndex { this:circles at:anIndex. }
    -description {
       count := this:circles count.
       "{count} circles". 
    }
    -atLocation:aLocation {
          foundIndex := -1 .
          self count > 0 ifTrue: {
               (0 to: self count -1 ) do: { :theIndex |
                  theCircle := this:circles at:theIndex.
                  (theCircle contains: aLocation) ifTrue: {
                        stdout println:'Found one'.
                        foundIndex := theIndex.
                  }.
              }.
          }.
          foundIndex.
    }
    -count {
       this:circles count.
    }
    +<void>testCanAddCircles {
        circles := #Circles{}.
        circles count assertEqual:0 msg:'empty after creation'.
        circles addCircleAt: (125 @ 34 ).
        circles count assertEqual:1 msg:'1 after add'.
	pt2 := 125@34.
        (circles atIndex:0 ) center assertEqual:pt2 msg:'location of added circle'.
        (circles atIndex:0 ) radius assertEqual:10  msg:'radius of added circle'.
    }
    +<void>testIndexOfCircleAtLocation {
        circles := #Circles{}.
        (circles atLocation: 126@2) assertEqual:-1 msg:'no circles, so not found'.
        circles addCircleAt: (125 @ 34 ).
        (circles atLocation: 126@30) assertEqual:0 msg:'first circle found'.
    }

    +testSelectors { [
         'testCanAddCircles',
         'testIndexOfCircleAtLocation',
       ]. 
    }
}. 
 


init:circles ← #Circles{}.

class CircleView  : MPWView {
    var circles.
    -<void>drawOnContext:aContext {
           aContext setStrokeColor: (aContext colorRed:1 green:0 blue:0 alpha:1).
           self circles drawOn: aContext.
    }
    -<void>mouseUp:event {
           location := self convertPoint: (event locationInWindow) fromView: nil.
           stdout println: location.
           self circles addCircleAt: location.
          self setNeedsDisplay: true.
    }
-<bool>logDrawRect {
    true
   }
}.

slider ← #Slider{
    #frame: (200@20),
    #minValue: 0,
    #maxValue: 200,
    #doubleValue: 10,
    #binding: ref:model:circles/currentRadius 
}.  

#VStack{   #frame: (500 @400 ) ,  #views: [   
slider,
#CircleView{  #circles: model:circles } ] }.
Circles.