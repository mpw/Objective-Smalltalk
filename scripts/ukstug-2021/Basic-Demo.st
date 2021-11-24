It's a Smalltalk!

3 + 4    

Strings + Interpolation

'Hello, ', 'World'   

greete ← 'UK Smalltalk User''s Group'.  

"Hello {greete}".      


Collections and enumerating

#( 1, 2, 3, 4 )  

#( 1, 2, 3, 4 )  collect: { :each | each * 5. }  

(1 to: 4) collect: { :each | each * 5. }   

(1 to: 4) collect: { $0 * 5. }      

Higher Order Messaging

#( 1, 2, 3, 4 )  collect * 5. 

'Hello, ' collect , #( 'World!', 'UKSTUG!' ) each. 

Class syntax

class Greeter { 
   -hello:greete {
          "Hello {greete}".      
   }
}.
 
Greeter new hello:'World!'


Extensions

extension NSNumber {
      -factorial {
           (2 to:self) reduce * 1.
      }
}. 
 
Framework loading

framework:ObjectiveArithmetic load.  

extension MPWStScanner { -defaultIntClass { MPWBigInteger. }}.   

100 factorial.  
