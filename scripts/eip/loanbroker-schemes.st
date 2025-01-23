#!env st
#-<void>broker

class LoanApplication {
   var ssn.
   var amount.
   var rating.
}.

scheme RatingAgency {
   /rating/:ssn { get {
       100.0 to: 200.0 | random.
   } }
}

class LoanOffer {
   var application.
   var duration.
   var interest.
   var amount.
   var ssn.
   -<int>compare: other {
       self interest compare: other interest.
   }
   -description { "Offer for {this:amount} to:{this:ssn} at:{this:interest} for: {this:duration} years}". }
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
              #LoanOffer{ ssn: (thisApplication ssn), amount: 0, application:thisApplication, duration:10, interest: 100  }.
         }.
      }
   }
   -apply:thisApplication {
      thisApplication rating > this:minRating ifTrue: { 
	      #LoanOffer{ ssn: (thisApplication ssn), amount: (thisApplication amount), application:thisApplication, duration:10, interest: (self interest )  }.
      } ifFalse: {
              #LoanOffer{ ssn: (thisApplication ssn), amount: 0, application:thisApplication, duration:10, interest: 100  }.
	}.
      }
   }.

stdout println:'after bank'.


class LoanBroker {
    var banks.
    var agency.
    -schemeNames { #[ 'agency' ] } 
    -init { 
       self ← super init.
       this:banks ← #[ #Bank{ name: 'Bank 1' , minRating:500 }, #Bank{ name:'Bank 2', minRating: 400 } , #Bank{ name:'Bank 3', minRating: 550 }].
       self.
    }

    -selectBestOffer: loans {
       loans sorted lastObject.
    }
    -selectBestOfferComplex: loans {
       bestOffer ← loans firstObject.
       loans do: { :aLoan | 
           aLoan interest < bestOffer interest ifTrue: {
              bestOffer ← aLoan.
           }.
       }.
       bestOffer.
    }
    -getOffers: ssn rating: rating amount:amount  {
        this:banks collect: { :bank | 
	     bank at: ref:var:loanFor/{ssn}/rating/{rating}/amount/{amount}  .
        }.
    }
    -apply: theApplication {
        ssn ← theApplication ssn.
        theApplication setRating: agency:rating/{ssn} .
        stdout println: theApplication rating.
        allApproved ← self getOffers: ssn rating: theApplication rating amount: theApplication amount.
        stdout println: allApproved sorted.
        self selectBestOffer: allApproved.
    }
    -description { "Loan broker with banks: {this:banks}." }
}

stdout println:'after loanbroker'.

broker ← #LoanBroker{ agency: #RatingAgency{} } .
stdout println: broker.
application ← #LoanApplication{ ssn: '123123', amount: 2000}.
stdout println: (broker apply: application).

