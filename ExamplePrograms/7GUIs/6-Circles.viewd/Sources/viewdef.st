extension MPWCGDrawingContext {
    -circleAt: point  radius:radius {
          self arcWithCenter:point  radius:radius startDegrees:0 endDegrees:360  clockwise:false; stroke.
       self.
    }
    -circle: aCircle  {
        self circleAt: aCircle center radius: aCircle radius.
        self.
    }
}.

class Circle {
    var center.
    var radius.
}.

circles ← [ #Circle{ #center: (200@100), #radius: 10 },  #Circle{ #center: (120@300), #radius: 40 },  #Circle{ #center: (150@300), #radius: 40 } ].

class CircleView  : MPWView {
    var circles.
    -<void>drawOnContext:aContext {
           stdout println:'should draw here'. 
           aContext setStrokeColor: (aContext colorRed:1 green:0 blue:0 alpha:1).
           aCircle := self circles firstObject.
           stdout println:aCircle radius.
           aContext do circle: self circles each.
    }
-<bool>logDrawRect {
    true
   }

}.
 
v ← #CircleView{ #circles: circles } . 
stdout println: v circles firstObject radius.
v. 
 