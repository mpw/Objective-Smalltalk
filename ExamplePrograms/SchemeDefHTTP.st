scheme Hello 
{
   /hi/:p1 {
      get { 
	'hello: ',p1.
     }
   }
   -main:args
   {
        self waitOnPort: 8081 intValue.
   }
}
