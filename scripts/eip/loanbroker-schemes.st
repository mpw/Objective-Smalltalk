#!env st
#-<void>broker


scheme RatingAgency {
   /rating/:ssn { get {
       400.0 to: 500.0 | random.
   } }
}

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
	    #LoanOffer{ ssn:ssn, amount: amount , duration:10, interest: (self interest )  }.
         } ifFalse: {
	    #LoanOffer{ ssn:ssn, amount: 0 , duration:0, interest: 100  }.
         }.
      }
   }
   /*:uri { get {
	stdout println: 'unknown uri: ', uri stringValue.	
   } }
   }.

stdout println:'after bank'.


class LoanBroker {
    var banks.
    var agency.
    -schemeNames { #[ 'agency' ] } 

    -selectBestOffer: loans {
       loans sorted firstObject.
    }
    -getOffers: ssn rating: rating amount:amount  {
        this:banks collect: { :bank | 
	     bank at: ref:var:dummy/loanFor/{ssn}/rating/{rating}/amount/{amount}  .
        }.
    }
    -apply: ssn amount: amount {
        rating ← agency:rating/{ssn} .
        allApproved ← self getOffers: ssn rating: rating amount: amount.
        stdout println: allApproved.
        self selectBestOffer: allApproved.
    }
    -description { "Loan broker with banks: {this:banks}." }
}

stdout println:'after loanbroker'.

banks ← #[ #Bank{ name: 'Bank 1' , minRating:500 }, #Bank{ name:'Bank 2', minRating: 400 } , #Bank{ name:'Bank 3', minRating: 550 }].

broker ← #LoanBroker{ agency: #RatingAgency{} , banks: banks } .
stdout println: broker.
stdout println: (broker apply: '12312312' amount: 2000).

