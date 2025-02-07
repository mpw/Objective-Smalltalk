#!env st
#-<void>broker

class LoanApplication {
   var ssn.
   var amount.
   var rating.
}.

class RatingAgency {
   -creditRating: anApplication {
       500.0 to: 700.0 | random.
   }
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

class Bank {
   var name.
   var minRating.
   -interest {
	1.2 to: 4.4 | random.
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
    var ratingAgency.
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
    -getOffers: theApplication {
        this:banks collect  apply: theApplication .
    }
    -apply: theApplication {
        theApplication setRating: (this:ratingAgency creditRating:theApplication).
        allApproved ← self getOffers: theApplication.
        stdout println: allApproved sorted.
        self selectBestOffer: allApproved.
    }
    -description { "Loan broker with banks: {this:banks}." }
}


stdout println:'after loanbroker'.

broker ← #LoanBroker{ ratingAgency: #RatingAgency{} } .
stdout println: broker.
application ← #LoanApplication{ ssn: '123123', amount: 2000}.
stdout println: (broker apply: application).

