class Person {
    var first.
    var last.
    -fullName {  this:first , ' ', this:last. }
    -allKeys {  [ 'fullName' ]. }
    -description { self fullName. }
    -copyWithZone:<int>aZone {
        copy ← self class new.
        copy setFirst: self first.
        copy setLast: self last.
        copy.
    }
}.
    
model:people ← #MPWArrayWithCursor[ 
   #Person{ #first: 'Marcel', #last: 'Weiher' } ,
   #Person{ #first: 'Steven', #last: 'Pinker' } ,
   #Person{ #first: 'Daniel', #last: 'Oschatz' } ,
   #Person{ #first: 'Alex', #last: 'Weiher' } ,
].


model:people setOffset:2.
a := model:people/selectedObject.
stdout println:a.  

model:initialvalue := model:people firstObject.
model:initialcursor := ref:model:initialvalue.
model:cursor := ref:model:initialvalue.

table ← #MPWTableView{ #frame: (00@300), #cursorRef: ref:model:cursor , #binding: ref:model:people   }.
table setItems: model:people.
table ← table  inScrollView:(200@400 extent: 500@600).
create ← #Button{ #title: 'Create' }.
update ← #Button{ #title: 'Update' }.
delete ← #Button{ #title: 'Delete' }.

#VStack{ #views: [   
 #HStack{ #views:[ #Label{ #stringValue: 'Filter prefix:'  }, #TextField{} ] }, 
  #HStack{ #views:[ table  , 
      #Grid{ #rows: [ 
            [ #Label{ #text: 'First:'} , #TextField{ #binding: ref:model:people/selectedObject/first  }] ,
            [ #Label{ #text: 'Last:'} , #TextField{ #binding: ref:model:people/selectedObject/last }] ] } 
    ] } , 
   #HStack{ #views:[  create, update, delete ] },
] }. 