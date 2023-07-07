scheme Hello 
{
   /hi {
      get { 
	'Hello World'.
     }
   }
   /hi/:p1 {
      get { 
	'Hello, ' stringByAppendingString:p1.
     }
   }
   /* { get { 'Backup'. }}
   -main:args
   {
        self Stdout println: self GET_hi.
        self Stdout println: (self performSelector: 'GET_hi/:p1' asSelector withObject: args lastObject) .
        0.
   }
}
