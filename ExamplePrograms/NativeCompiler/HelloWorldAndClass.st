class Hello
{
   +someClassMethod { 32. }
   -main:args
   {
        self Stdout println:'Hello ObjS native world!'.
        self Stdout println: self class someClassMethod stringValue.
        0.
   }
}
