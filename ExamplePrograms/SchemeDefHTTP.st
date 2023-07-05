scheme Hello 
{
   /hi {
      |= { 
	self Stdout println:'Hello'.
	'Hello World'.
     }
   }
   /* { |= { 'Backup'. }}
   -main:args
   {
        self Stdout println: self GET_hi.
        self serveOnPort:9001 intValue.
        class:NSRunLoop currentRunLoop run.
        0.
   }
}
