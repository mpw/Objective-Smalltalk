model:count ← 1.
#Grid{ #rows: [   
 [ #Label{  ref:  ref:model:count  },
  (#Button{ title: 'count' } → { model:count ← model:count + 1.  }) ]
] }. 
   