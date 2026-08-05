class Person {
   var name.
   var age:int.
   -description {
      'Person: ', this:name.
   }
   -<void>sayHelloIf {
     this:age > 30 ifTrue: { stdout println:'hello'. }.
   }
   -<void>sayHelloIfElse {
     this:age > 30 ifTrue: { stdout println:'hello'. } ifFalse:{ stdout println:'hi'.}.
   }
   -hello {
     this:age > 30 ifTrue:{ 'hi'. } ifFalse: { 'howdy'. }.
   } 
   -<void>advance {
       this:age ← this:age + 1.
    }
}
