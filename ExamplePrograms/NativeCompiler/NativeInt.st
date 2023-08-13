class Hello
{
   -main:args
   {
        var <int> from.
        from := 4.
        self Stdout println:('Hello ObjS native world!' substringFromIndex:from).
        0.
   }
}

