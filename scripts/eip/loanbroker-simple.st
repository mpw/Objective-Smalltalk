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
    -apply: theApplication {
        approved ← this:banks collect  apply: theApplication .
        approved.
    }
    -description { "Loan broker with banks: {this:banks}." }
}



banks ← #[ #Bank{ name: 'Bank 1' } , #Bank{ name:'Bank 2'} , #Bank{ name:'Bank 3' }].

broker ← #LoanBroker{} .

stdout println: broker.

application ← #LoanApplication{ ssn: '123123', amount: 2000}.

stdout println: application.

stdout println: (broker apply: application).

