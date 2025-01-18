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
   -apply:application {
      #LoanOffer{ ssn: (application ssn), amount: (application amount), application:application, duration:10, interest:4 }. 
   }
}


bank1 ← #Bank{ name:'Bank 1' }.

stdout ! (bank1 apply: #LoanApplication{ ssn: '123123', amount: 2000}).

