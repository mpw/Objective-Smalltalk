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
   #{ first: 'Marcel', last: 'Weiher' } ,
   #{ first: 'Steven', last: 'Pinker' } ,
   #{ first: 'Daniel', last: 'Oschatz' } ,
   #{ first: 'Alex', last: 'Weiher' } , 
].

model:people setOffset:2.
a := model:people/selectedObject.

model:cursor := MPWArrayCursor alloc initWithArray: model:people.
current ← #MPWInstanceVarStore{ baseReference: model:cursor }.
scheme:cur ← current.
 
model:cursor setSelectionChanges: protocol:ModelDidChange. 
model:cursor setModelChanges: protocol:ModelDidChange. 

table ← #MPWTableView{ #frame: (00@300), #cursor: model:cursor , #binding: ref:model:people   }.
table setItems: model:people.
table ← table  inScrollView:(200@400 extent: 500@600).
create ← #Button{ #title: 'Create' }.
update ← #Button{ #title: 'Update' }.
delete ← #Button{ #title: 'Delete' }.

 
f1 ←  #TextField{ binding: ref:cur:first  }.
f2 ←  #TextField{ binding: ref:cur:last  }.

#VStack{ views: [   
 #HStack{ views:[ #Label{ #stringValue: 'Filter prefix:'  }, #TextField{} ] }, 
  #HStack{ views:[ table  , 
      #Grid{ rows: [ 
            [ #Label{ #text: 'First:'} , f1 ] ,
            [ #Label{ #text: 'Last:'} , f2 ] ] } 
    ] } , 
   #HStack{ #views:[  create, update, delete ] },
] }. 
