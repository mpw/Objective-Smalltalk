#!env st
#-<void>broker


framework:ObjectiveHTTPD load.
framework:ObjectiveHTTPD load.

class LoanOffer {
   var duration.
   var interest.
   var amount.
   var ssn.
   -<int>compare: other {
       self interest compare: other interest.
   }
   -description { "Offer for {this:amount} to:{this:ssn} at:{this:interest} for: {this:duration} years}\n". }
}.

stdout println:'before bank'.

scheme Bank {
   var name.
   var minRating.
   -interest {
	1.2 to: 4.4 | random.
   }
   /loanFor/:ssn/rating/:rating/amount/:amount { get { 
      rating floatValue > this:minRating ifTrue: { 
	    #LoanOffer{ ssn:ssn, amount: (amount intValue) , duration:10, interest: (self interest )  }.
         } ifFalse: {
	    #LoanOffer{ ssn:ssn, amount: 0 , duration:0, interest: 100  }.
         }.
      }
   }
   /*:uri { get {
	stdout println: 'unknown uri: ', uri stringValue.	
   } }
}


bank ← #Bank{ minRating: 300 }.
json ← #MPWJSONConverterStore{  #up: true, converterClass: class:LoanOffer  }.

stdout println: bank.
stdout println: json.

server ← #MPWHTTPServer{ port:8081  }.


json → bank.


scheme:bank ← bank.

stdout println: bank:loanFor/123123/rating/700/amount/100000 .

json serveOnPort:8081.


shell runInteractiveLoop.

