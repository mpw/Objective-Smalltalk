It's a Smalltalk!
--------------------

3 + 4     

Strings + Interpolation
------------------------------

'Hello, ', 'World'     

greete ← 'UK Smalltalk User''s Group'.   

"Hello {greete}".        


Collections and enumerating
--------------------------------------

#( 1, 2, 3, 4 )   

#( 1, 2, 3, 4 )  collect: { :each | each * 5. }   

(1 to: 4) collect: { :each | each * 5. }    

(1 to: 4) collect: { $0 * 5. }   

    

Higher Order Messaging
---------------------------------

#( 1, 2, 3, 4 )  collect * 5.  

'Hello, ' collect , #( 'World!', 'UKSTUG!' ) each.  


Indexing 
-----------


d := #{ #question: 2 , #answer: 42 }.  

d['answer']  

Cascades
--------------

1 to: 4 | * 5    


Class syntax
-----------------

class Greeter  { 
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
 
20 factorial   
 
Framework loading
--------------------------


framework:ObjectiveArithmetic load.   

extension MPWStScanner { -defaultIntClass { MPWBigInteger. }}.    

100 factorial.   93326215443944152681699238856266700490715968264381621468592963895217599993229915608941463976156518286253697920827223758251185210916864000000000000000000000000


Simple UI
--------------

#MPWBrowser{ #store: scheme:file } openInWindow:'Disk'.  

