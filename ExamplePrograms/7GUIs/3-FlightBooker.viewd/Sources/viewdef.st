now ← NSDate now.

model:from :=  now.
model:to :=   now.
model:flightType := 0. 
   
class Validator  {
   var toRef.
   var fromRef.
   var flightTypeRef.
   -isReturn {
          self flightTypeRef value = 1.
   } 
   -isFromValid {
         self fromRef isBound.
   }
   -isToValid {
        self isReturn ifTrue: { self toRef value > self fromRef value. } ifFalse: { true. } .
   }
   -canBook {   (self isFromValid and:self isToValid) and: true. }
}. 
 
validator ← #Validator{ 
   #toRef: ref:model:to ,
   #fromRef: ref:model:from ,
   #flightTypeRef: ref:model:flightType
}.

formatter ← NSDateFormatter new.
formatter setDateStyle: c:NSDateFormatterMediumStyle.


#Grid{ #rows: [   
   [ #PopUp{ #frame: (0@0 extent:200@120),
   #items: [ 'one way', 'return' ] , #binding: ref:model:flightType }],
   [ #TextField{  #binding: ref:model:from , #formatter: formatter  }],
   [ #TextField{  #binding: ref:model:to , #enabledRef: ref:var:validator/isReturn , #formatter: formatter}  ],
   [ #Button{ #title:  'Book', #enabledRef: ref:var:validator/canBook } ],
] }.
 
