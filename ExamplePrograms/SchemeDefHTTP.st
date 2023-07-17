scheme Hello 
{
   /hi {
      get { 
	'Simple GET Property Path without parameters'.
     }
   }
   /hi/:p1 {
      get { 
	p1.
     }
   }
   -main:args
   {
        self Stdout println: self class superclass.
        self serveOnPort: 8081 intValue.
        class:NSRunLoop currentRunLoop run.
        0.
   }
}
