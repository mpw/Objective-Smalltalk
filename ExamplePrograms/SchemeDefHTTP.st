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
        self serveOnPort:9001 intValue.
        class:NSRunLoop currentRunLoop run.
        0.
   }
}
