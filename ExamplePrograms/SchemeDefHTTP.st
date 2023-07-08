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
        self Stdout println: self GET_hi.
        self Stdout println: (self performSelector: 'GET_hi/:p1' asSelector withObject: args lastObject) .
        0.
   }
}
