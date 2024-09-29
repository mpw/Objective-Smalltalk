  
model:people ← [ 
   #{ first: 'Marcel', last: 'Weiher' } ,
   #{ first: 'Steven', last: 'Pinker' } ,
   #{ first: 'Daniel', last: 'Oschatz' } ,
   #{ first: 'Alex', last: 'Weiher' } , 
].
 
model:filtered ← model:people.

model:cursor := MPWArrayCursor alloc initWithArray: model:people.
scheme:cur ← #MPWInstanceVarStore{ baseReference: model:cursor }.
 
model:cursor setSelectionChanges: protocol:ModelDidChange. 
table ← #MPWTableView{ frame: (200@300), cursor: model:cursor , binding: ref:model:filtered   }.

prefixField ← #TextField{}. 
prefixField → { :filterValue | model:filtered ← model:people select: { :dict | (dict at:'first') containsString:filterValue  .  }.  stdout println: model:filtered. table setItems:model:filtered. table reloadData. }.

table setItems: model:filtered.
 
#VStack{ views: [   
 #HStack{ views:[ #Label{ #stringValue: 'Filter prefix:'  }, prefixField ] }, 
  #HStack{ views:[ (table  inScrollView:(200@400 extent: 500@600))  , 
      #Grid{ rows: [ 
            [ #Label{ #text: 'First:'} , #TextField{ binding: ref:cur:first  } ] ,
            [ #Label{ #text: 'Last:'} , #TextField{ binding: ref:cur:last  } ] ] } 
    ] } , 
   #HStack{ #views:[  #Button{ title: 'Create' }, #Button{ title: 'Update' }, #Button{ title: 'Delete' } ] },
] }. 
