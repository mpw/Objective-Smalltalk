#!env raspish
last := 0.
{true} whileTrue:{ 
	new := gpio:21.
	last = new ifFalse:{
		last := new.
		stdout println:new.
	}.
}.
