t1 ← #TextField{ #stringValue:'t1' , #frame: (60@20) } .
t2 ← #TextField{ #stringValue:'t2' , #frame: (60@20)}.
stdout println: t1.
stdout println: t2.

grid ← #Grid{  #frame: (400 @ 200),  #rows:[
  [ #Label{ #stringValue:'AAAA '} ,  #Label{ #stringValue:'BBBBBB'},  #Label{ #stringValue:'CCCCCC '} , #Label{ #stringValue:'DDDDD '},  #Label{ #stringValue:'EEEEEE '}  ],
 (( 1 to: 5 ) collect: { #TextField{ #frame: (180 @ 10 ) }.   } ) ,
 (( 1 to: 5 ) collect: { #TextField{#frame: (80 @ 10 )  }.   } ) ,
  ]
 }. 
 
stdout println: grid.
grid.