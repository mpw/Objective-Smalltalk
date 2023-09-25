class Timer {
    var start.
    var duration.
    -seconds {
          this:duration min: (NSDate now timeIntervalSinceReferenceDate - this:start timeIntervalSinceReferenceDate) intValue.
    }
    -<void>reset {
           this:start ← NSDate now.
    }
    -<void>adjustMax:slider {
            this:duration ← slider intValue.
            self reset.
   }
}.
 
timer ← #Timer{ 
      #duration: 15,
      #start: #NSDate{}
}.
stdout println: timer seconds.

source ← #MPWFixedValueSource{ #values: [ '' ], #seconds: 1 }.
source → (MPWNotificationStream alloc initWithNotificationProtocol: protocol:ModelDidChange shouldPostOnMainThread:false) autorelease.

button ← #Button{ #title: 'Reset' }.
button → {  timer reset. }.

slider ← #Slider{
    #minValue: 0,
    #maxValue: 20,
    #doubleValue: 10,
    #binding: ref:var:timer/duration
}.  
 
progress ← NSProgressIndicator alloc initWithFrame: ((200 @ 20 ) extent: (200 @ 20 )).
progress setMinValue:0.
progress setMaxValue:20.
progress setDoubleValue:5.

#Grid{ #frame: (400@500) ,  #rows: [   
 [ #Label{ #stringValue: 'Elapsed Time:'  },  ],
 [  progress ],
 [ #Label{ #ref:  ref:var:timer/seconds  },#Label{ #stringValue: 's'  } ], 
 [ #Label{#stringValue: 'Duration:'  } , slider ],
 [ button ],
] }.


 