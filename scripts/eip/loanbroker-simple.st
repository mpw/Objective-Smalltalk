#!env st
#-<void>broker

class LoanApplication {
   var ssn.
   var amount.
   var creditRating.
}.

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

class Bank {
   var name.
   -interest {
	1.2 to: 4.4 | random.
   }
   -apply:thisApplication {
      #LoanOffer{ ssn: (thisApplication ssn), amount: (thisApplication amount), application:thisApplication, duration:10, interest: (self interest )  }. 
   }
}

class LoanBroker {
    var banks.
    -init { 
       self ← super init.
       this:banks ← #[ #Bank{ name: 'Bank 1' } , #Bank{ name:'Bank 2'} , #Bank{ name:'Bank 3' }].
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
        allApproved ← self getOffers: theApplication.
        stdout println: allApproved sorted.
        self selectBestOffer: allApproved.
    }
    -description { "Loan broker with banks: {this:banks}." }
}



broker ← #LoanBroker{} .
application ← #LoanApplication{ ssn: '123123', amount: 2000}.
stdout println: (broker apply: application).

