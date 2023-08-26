count ← 1.

button ← #NSButton{ #title: 'count' }.
button → { count ← count + 1. protocol:ModelDidChange notify. }.

NSGridView gridViewWithSize: 150@140 views:[   
 [ #Label{ #stringValue:'Counter: ' }, #STTextField{ #ref: ref:var:count }, button ]
].  
