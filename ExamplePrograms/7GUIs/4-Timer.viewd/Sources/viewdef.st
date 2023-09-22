time ← 1.

button ← #Button{ #title: 'Reset' }.
button → { count ← count + 1. protocol:ModelDidChange notify. }.

#Grid{ #rows: [   
 [ #Label{ #stringValue: 'Elapsed Time:'  },  ],
 [ #Label{ #ref:  ref:var:time  },#Label{ #stringValue: 's'  } ], 
 [ #Label{#stringValue: 'Elapsed Time:'  }  ],
 [ button ],

] }. 
  