
class Counter {
   var currentCount.
   var countDisplay.
   -<void>count:sender {
           this:currentCount ← this:currentCount + 1.
          this:countDisplay setIntValue: this:currentCount.
   }
}.

f ← #Label{  #intValue: 0 }.
button ← #NSButton{ #title: 'count' }.
counter ← #Counter{ #countDisplay: f , #currentCount: 0 }.
button setTarget: counter.
button setAction: #count: .


NSGridView gridViewWithSize: 150@140 views: #(   
 #( #Label{  #stringValue:'Counter: ' }
 ,f  ,button ),
).

 