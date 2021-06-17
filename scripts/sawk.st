#!env stsh
#-oawk:<ref>file
file lines do:{ :line |
	fields ← line componentsSeparatedByString:','.
	{ 
		stdout println:'Magnitude: ', $4.
	} valueWithObjects:fields.
}.
