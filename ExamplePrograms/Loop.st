class Hello
{
   -main:args
   {
	1 to: 10 do: { :i |
		self Stdout println:'Hello ObjS loopy world: ' , i stringValue.
	}.
        0.
   }
}
