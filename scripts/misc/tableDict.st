extension NSArray {
   -tableArray { 
          keys ← self firstObject.
          rows := (1 to: self count - 1 ) collect: { :i |
               row := self at:i.
               NSDictionary dictionaryWithObjects: row forKeys: keys.
          }.
   } 
   -tableDict { 
          keys ← self firstObject.
          result ← #NSMutableDictionary{}.
          rows := (1 to: self count - 1 ) collect: { :i |
               row := self at:i.
               dict := NSDictionary dictionaryWithObjects: row forKeys: keys.
               result at: (dict at:keys firstObject) put:dict.
          }.
          result.
   } 

}.

[ 
  [ 'id', 'First' , 'Last'  ] ,
  [ 22, 'Marcel', 'Weiher' ],
  [ 23, 'Peter', 'Pan' ] ,
] tableDict.      