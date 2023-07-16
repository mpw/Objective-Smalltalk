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
        self Stdout println: (self at:'hi').
        self Stdout println: (self at:('hi/' , args lastObject )).
        0.
   }
}
