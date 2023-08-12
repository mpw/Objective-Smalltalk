scheme PropertyPathTesterScheme 
{
   /hi {
      get { 
	'Simple GET Property Path without parameters'.
     }
   }
   -main:args
   {
        self Stdout println: self GET_hi.
        0.
   }
}
