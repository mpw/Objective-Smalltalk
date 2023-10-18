init:count ← 1.
button ← #Button{ #title: 'Count' }.
button → { model:count ← model:count + 1.   }.
#Grid{ #rows: [   
 [ #Label{ #ref: ref:model:count  }, button ]
] }. 