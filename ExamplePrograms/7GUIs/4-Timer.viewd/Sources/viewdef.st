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
source ← #MPWFixedValueSource{ #values: [ '' ], #seconds: 1 }.

button ← #Button{ #title: 'Reset' }.
slider ← #Slider{
    #frame: (200@20),
    #minValue: 0,
    #maxValue: 20,
    #doubleValue: 10,
}.  

button →  {  timer reset. }.
slider   →  {  var:timer/duration ← slider doubleValue intValue. timer reset }.
source →  (MPWNotificationStream alloc initWithNotificationProtocol: protocol:ModelDidChange shouldPostOnMainThread:false) autorelease.

"source start".

#Grid{ #frame: (400@140) ,  #rows: [   
 [ #Label{ #stringValue: 'Elapsed Time:'  },  ],
 [  #ProgressIndicator{ #frame: (200 @ 20 ),
     #minValue: 0,
     #maxValue: 50,
     #ref: ref:var:timer/seconds ,
     #maxRef: ref:var:timer/duration ,
} ],
 [ #Label{ #ref:  ref:var:timer/seconds  },#Label{ #stringValue: 's'  } ], 
 [ #Label{#stringValue: 'Duration:'  } , slider ],
 [ button ],
] }.


 