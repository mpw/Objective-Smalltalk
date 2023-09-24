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
      #duration: 20,
      #start: #NSDate{}
}.
stdout println: timer seconds.

source ← #MPWFixedValueSource{ #values: [ '' ], #seconds: 1 }.
source → (MPWNotificationStream alloc initWithNotificationProtocol: protocol:ModelDidChange shouldPostOnMainThread:false) autorelease.

button ← #Button{ #title: 'Reset' }.
button → {  timer reset. }.

slider ← NSSlider  sliderWithValue:10 minValue:0 maxValue:50 target: timer  action: #adjustMax: .

progress ← NSProgressIndicator alloc initWithFrame: ((200 @ 20 ) extent: (200 @ 20 )).
progress setMinValue:10.
progress setMaxValue:20.


#Grid{ #rows: [   
 [ #Label{ #stringValue: 'Elapsed Time:'  },  ],
 [  progress ],
 [ #Label{ #ref:  ref:var:timer/seconds  },#Label{ #stringValue: 's'  } ], 
 [ #Label{#stringValue: 'Duration:'  } , slider ],
 [ button ],
] }.


 