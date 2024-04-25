#!env st
framework:ObjectiveHTTPD load.
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
}

Hello scheme serveOnPort: 8081 
NSRunLoop currentRunLoop run.
