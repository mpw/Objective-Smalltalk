class Person {
    var first.
    var last.
}.


button ← #Button{ #title: 'Reset' }.
button → {  timer setStart: NSDate now.  }.

#Grid{ #rows: [   
 [ #Label{ #stringValue: 'Elapsed Time:'  },  ],
 [ #Label{ #ref:  ref:var:timer/seconds  },#Label{ #stringValue: 's'  } ], 
 [ #Label{#stringValue: 'Duration:'  }  ],
 [ button ],
] }.


