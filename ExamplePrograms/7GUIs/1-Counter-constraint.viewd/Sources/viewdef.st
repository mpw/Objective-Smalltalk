model:count ← 1.

button ← #Button{ #title: 'count' }  → {  model:count ← model:count + 1.  }.
label ←   #Label{ intValue: model:count }.
var:label/intValue |= model:count.

#Grid{ #rows: [   
 [ label, button ]
] }. 
