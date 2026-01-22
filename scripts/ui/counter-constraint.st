#!env stui

model:count ← 1.

grid ←  #Grid{ #rows: [   
 [ (#Label{ text: '1'} |= model:count)  ,
  (#Button{ title: 'count' } → { model:count ← model:count + 1. stdline ! model:count.  } ) ]
] }. 
