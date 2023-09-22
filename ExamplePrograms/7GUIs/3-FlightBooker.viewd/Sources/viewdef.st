now ← NSDate now.
model:from :=  now.
model:to :=   now.
model:flightType := 0.
canBook := false.
 
   
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
        self isReturn ifTrue: { self toRef value > self fromRef value. } ifFalse: { 1. } .
   }
   -canBook {   (self isFromValid and:self isToValid) and: true. }
}. 
 
validator ← #Validator{ 
   #toRef: ref:model:to ,
   #fromRef: ref:model:from ,
   #flightTypeRef: ref:model:flightType
}.
 
stdout println: ref:var:validator/isReturn.

fromField  ← #TextField{  #ref: ref:model:from }.
toField      ← #TextField{  #ref: ref:model:to , #enabledRef: ref:var:validator/isReturn } .

 
locale ← NSLocale alloc initWithLocaleIdentifier:'en_US'.
formatter ← NSDateFormatter new.
formatter setDateStyle: c:NSDateFormatterMediumStyle.

fromField setFormatter: formatter.
toField setFormatter: formatter.

popup ← #PopUp{ #frame: (0@0 extent:200@120),
   #items: [ 'one way', 'return' ] , #ref: ref:model:flightType }.

button ←  #Button{ #title:  'Book', #enabledRef: ref:var:validator/canBook }.
popup setRef: ref:model:flightType.

popup → { model:flightType ← popup objectValue. } .
fromValidator ← { :string | model:from ← formatter objectValue: string. }.
toValidator ← { :string |  model:to ← formatter objectValue: string.  }.

fromField → fromValidator.
toField → toValidator.
#Grid{ #rows: [   
   [ popup],
   [ fromField],
   [ toField  ],
   [ button ],
] }.
  
