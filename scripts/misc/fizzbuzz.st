 1 to: 100 do:{ :i | fizz := ((i mod:3) = 0). buzz := ((i mod:5) = 0).  s:=i. fizz ifTrue:{s :='fizz'}. buzz ifTrue:{ s:='buzz'}. (buzz * fizz) ifTrue:{s := 'fizzbuzz'} . stdout println:s. }.
