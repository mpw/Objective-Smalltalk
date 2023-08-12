class Hello
{
   -main:args
   {
	var max.
        var stdout.
        stdout := self Stdout.
        max := class:NSNumber numberWithInt:args count.
	1 to: max - 1 do:{ :i |
		stdout println: args[i].
	}.
        0.
   }
}

#Hello new main: [1,2,3].
