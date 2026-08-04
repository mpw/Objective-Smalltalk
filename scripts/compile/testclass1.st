class Person {
   var name.
   var age:int.
   -description {
      'Person: ', name.
   }
   -hello {
     age > 30 ifTrue:{ 'hi'. } ifFalse: { 'howdy'. }.
   } 
}
