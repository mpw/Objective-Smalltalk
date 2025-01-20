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

filter Bank {
   var name.
   var broker.
   -interest {
	1.2 to: 4.4 | random.
   }
   -<void>writeObject:thisApplication {
      this:broker ! #LoanOffer{ ssn: (thisApplication ssn), amount: (thisApplication amount), application:thisApplication, duration:10, interest: (self interest )  }. 
   }
}

filter LoanBroker {
    var banks.
    var offers.
    -init { 
       self ← super init.
       this:banks ← #[ #Bank{ name: 'Bank 1', broker:self } , #Bank{ name:'Bank 2',broker:self} , #Bank{ name:'Bank 3',broker:self }].
       self.
    }
    -writeObject:anOffer {
	this:offers ! anOffer.
    }

    -selectBestOffer: loans {
       loans sorted firstObject.
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
         this:banks do ! theApplication .
    }
    -apply: theApplication {
        this:offers ← #NSMutableArray[] .
        self getOffers: theApplication.
        stdout println: this:offers sorted.
        self selectBestOffer: this:offers.
    }
    -description { "Loan broker with banks: {this:banks}." }
}



broker ← #LoanBroker{} .
application ← #LoanApplication{ ssn: '123123', amount: 2000}.
stdout println: (broker apply: application).

