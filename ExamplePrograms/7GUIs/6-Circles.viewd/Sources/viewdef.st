extension MPWCGDrawingContext {
    -circle: aCircle  {
          self arcWithCenter:aCircle center  radius:aCircle radius startDegrees:0 endDegrees:360  clockwise:false; stroke.
        self.
    }
}.
init:radius ← 10.

class Circle {
    var center.
    var radius.
}.

init:circles ← #NSMutableArray[ #Circle{ #center: ( 40@10), #radius: 10 },  #Circle{ #center: (120@300), #radius: 40 },  #Circle{ #center: (150@300), #radius: 40 } ].

class CircleView  : MPWView {
    var circles.
    var radius.
    -<void>drawOnContext:aContext {
           stdout println:'should draw here'. 
           aContext setStrokeColor: (aContext colorRed:1 green:0 blue:0 alpha:1).
           aCircle := self circles firstObject.
           stdout println:aCircle radius.
           aContext do circle: self circles each.
    }
    -<void>mouseUp:event {
           location := event locationInWindow.
           location := self convertPoint: location fromView: nil.
           stdout println: location.
           self circles addObject: #Circle{ #center: location , #radius: (self radius value) }.
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
    #binding: ref:model:radius 
}.  
 

#VStack{   #frame: (500 @ 400 ) ,  #views: [   
slider,
#CircleView{  #circles: model:circles , #radius: ref:model:radius } ] }.
