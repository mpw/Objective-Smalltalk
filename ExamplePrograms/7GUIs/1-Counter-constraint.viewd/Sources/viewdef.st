model:count ← 1.

button ← #Button{ #title: 'count' }  → {  model:count ← model:count + 1.  }.
label ←   #Label{ intValue: model:count }.
var:label/intValue |= model:count.
stdline ! 'hello world!'.
#Grid{ frame: (0@0 extent: 80 @ 16), #rows: [   
 [ label, button ]
] }. 
  