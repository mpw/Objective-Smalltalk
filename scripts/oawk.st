#!env stsh
#-oawk:<ref>file
file lines do:{
	fields ← $0 componentsSeparatedByString:','.
	{ :f1 :f2 |
		stdout println:'got something'.
		stdout println:'Second field: ', f2.
		stdout println:'printed field'.
	} valueWithObjects:fields.
}.
