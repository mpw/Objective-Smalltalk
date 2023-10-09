class Person {
    var first.
    var last.
    -fullName {  this:first , ' ', this:last. }
    -allKeys {  [ 'fullName' ]. }
    -description { self fullName. }
}.

people ← [ 
   #Person{ #first: 'Marcel', #last: 'Weiher' } ,
   #Person{ #first: 'Steven', #last: 'Pinker' } ,
   #Person{ #first: 'Daniel', #last: 'Oschatz' } ,
   #Person{ #first: 'Alex', #last: 'Weiher' } ,
].


table ← #MPWTableView{ #frame: (00@300) }.
table setItems: people.
table ← table  inScrollView:(200@400 extent: 500@600).
button ← #Button{ #title: 'Reset' }.
button → {  timer setStart: NSDate now.  }.

#VStack{ #views: [   
 #HStack{ #views:[ #Label{ #stringValue: 'Filter prefix:'  }, #TextField{} ] }, 
  #HStack{ #views:[ table  , 
      #Grid{ #rows: [ 
            [ #Label{ #text: 'First'} , #TextField{}] ,
            [ #Label{ #text: 'Last'} , #TextField{}] ] } 
    ] } , 
] }.


