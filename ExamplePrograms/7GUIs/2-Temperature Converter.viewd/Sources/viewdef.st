
filter f2c |{    ^object intValue - 32  / 1.8 | rounded.  }.
filter c2f |{    ^object intValue * 1.8 + 32 | rounded.  }.

celsiusField      ← #NumberField{ #intValue: 0 }.
fahrenheitField ← #NumberField{ #intValue:32 } .

celsiusField      →   c2f → fahrenheitField.
fahrenheitField →   f2c → celsiusField.

NSGridView gridViewWithSize: 150@140 views: #(   
   #(  celsiusField,       #Label{ #stringValue:'º Celsius '}  ),
   #(  fahrenheitField,  #Label{ #stringValue:'º Fahrenheit '}  ),
).
 