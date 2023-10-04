class Timer {
    var start.
    var duration.
    -seconds {
          this:duration min: (NSDate now timeIntervalSinceReferenceDate - this:start timeIntervalSinceReferenceDate)  intValue.
    }
    -<void>reset {
           this:start ← NSDate now.
    }
    -<void>adjustMax:slider {
            this:duration ← slider intValue.
            self reset.
   }
}.
  
init:timer ← #Timer{ 
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
 

source start.

view := #Grid{ #frame: (400@140) ,  #rows: [   
 [ #Label{ #stringValue: 'Elapsed Time:'  },  ],
 [  #ProgressIndicator{ #frame: (200 @ 20 ),
     #minValue: 0,
     #maxValue: 50,
     #ref: ref:model:timer/seconds ,
     #maxRef: ref:model:timer/duration ,
} ],
 [ #Label{ #ref:  ref:model:timer/seconds  },#Label{ #stringValue: 's'  } ], 
 [ #Label{#stringValue: 'Duration:'  } , slider ],
 [ button ],
] }.

button →  {  model:timer reset. }.
slider   →  {  model:timer/duration ← slider doubleValue intValue. model:timer reset }.
source →  (MPWNotificationStream alloc initWithNotificationProtocol: protocol:ModelDidChange shouldPostOnMainThread:false) autorelease.


 