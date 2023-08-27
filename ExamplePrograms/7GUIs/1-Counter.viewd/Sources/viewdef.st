count ← 1.

button ← #Button{ #title: 'count' }.
button → { count ← count + 1. protocol:ModelDidChange notify. }.

#Grid{   #rows: [   
 [ #Label{ #stringValue:'Counter: ' }, #Label{ #ref:  ref:var:count  }, button ]
]}.