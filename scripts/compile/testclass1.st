class Person {
   var name:String.
   var age:int.
   -description {
      'Person: ', name.
   }
   -hello {
     this:age > 30 ifTrue:{ 'hi'. } ifFalse: { 'howdy'. }.
   } 
}
