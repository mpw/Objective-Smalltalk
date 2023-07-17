scheme Hello 
{
   /hi {
      get { 
	'Simple GET Property Path without parameters'.
     }
   }
   /hi/:p1 {
      get { 
	'GET property path /hi/:p1 with paramater: ' stringByAppendingString:p1.
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
