now ← NSDate now.
model:from :=  now.
model:to :=   now.
model:flightType := 0.
model:canBook := false.
model:isReturn := false.
 

class Validator  {
   var toRef.
   var fromRef.
   var flightTypeRef.
   var enableTo.
   -init {
       self ← super init.
      self.
   }
   -isReturn {
          model:flightType = 1.
   } 
   -isFromValid {
         self fromRef isBound.
   }
   -isToValid {
        self isReturn ifTrue: { self toRef value > self fromRef value. } ifFalse: { 1. } .
   }
   -canBook {   true. }
   -<void>modelDidChange:notification { 
               ((notification object reference = ref:model:canBook  ) not and: 
               (notification object reference = ref:model:isReturn  ) not ) ifTrue: {
                    self validate.
               }.
   }
   -<void>validate {
          stdout println:'validating'.
          model:isReturn := self isReturn.
          model:canBook := self isFromValid and: self isToValid.
          stdout println: model:flightType.
          stdout println:'validated'.
    }
}.


validator ← #Validator{ 
   #toRef: ref:model:to ,
   #fromRef: ref:model:from
}.


fromField      ← #TextField{  #ref: ref:model:from }.
toField ← #TextField{  #ref: ref:model:to , #enabledRef: ref:model:isReturn } .


locale ← NSLocale alloc initWithLocaleIdentifier:'en_US'.
formatter ← NSDateFormatter new.
formatter setDateStyle: c:NSDateFormatterMediumStyle.

fromField setFormatter: formatter.
toField setFormatter: formatter.

popup ← STPopUpButton alloc initWithFrame: (0@0 extent:200@120) pullsDown:false.
popup addItemWithTitle:'one way'.
popup addItemWithTitle:'return'.
toField setEnabled: false.
button ←  #Button{ #title:  'Book', #enabledRef: ref:model:canBook }.
popup setRef: ref:model:flightType.

popup → { model:flightType ← popup object. validator validate. } 
fromValidator ← { :string | model:from ← formatter objectValue: string. validator validate. }.
toValidator ← { :string |  model:to ← formatter objectValue: string. validator validate. }.

fromField → fromValidator.
toField → toValidator.
#Grid{ #rows: [   
   [ popup],
   [ fromField],
   [ toField  ],
   [ button ],
] }.
  
