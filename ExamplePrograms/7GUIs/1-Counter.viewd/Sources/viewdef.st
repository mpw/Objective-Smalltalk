
class Counter {
   var currentCount.
   var countDisplay.
   -<void>count:sender {
           this:currentCount ← this:currentCount + 1.
          this:countDisplay setIntValue: this:currentCount intValue.
   }
}.

f ← #Label{  #intValue: 0 }.
button ← #NSButton{ #title: 'count' }.
counter ← #Counter{ #countDisplay: f }.
button → port:counter/count: .
counter setCurrentCount:0.
stdout println: ref:var:counter/currentCount .


NSGridView gridViewWithSize: 150@140 views: #(   
 #( #Label{  #stringValue:'Counter: ' }
 ,f  ,button ),
).