extension MPWCGDrawingContext {
    -circle: aCircle  {
          self arcWithCenter:aCircle center  radius:aCircle radius startDegrees:0 endDegrees:360  clockwise:false; stroke.
        self.
    }
}.

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
