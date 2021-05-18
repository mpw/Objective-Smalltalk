#!env raspish
last := 0.
{true} whileTrue:{ 
	newValue := gpio:21.
	last = newValue ifFalse:{
		last := newValue.
		stdout println:newValue.
	}.
}.
