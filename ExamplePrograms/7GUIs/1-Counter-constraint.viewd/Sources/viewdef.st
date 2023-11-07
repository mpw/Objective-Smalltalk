"Doesn't currently work".

model:count ← 1.

button ← #Button{ #title: 'count' }.
button → { model:count ← model:count + 1. protocol:ModelDidChange notify. }.
label ←   #Label{  }.
view := #Grid{ #rows: [   
 [ label, button ]
] }. 

label |= model:count.

view. 