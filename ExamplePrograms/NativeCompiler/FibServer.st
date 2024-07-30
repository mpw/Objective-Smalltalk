#!env st
framework:ObjectiveHTTPD load.
scheme FibServer
{
   -fib: n {
      n < 2 ifTrue: { n. } ifFalse: { (self fib:n - 1) + (self fib:n - 2). }.
   }
   /factorial/:n {
      get { 
	self fib: n intValue | stringValue.
     }
   }
}

FibServer scheme serveOnPort: 8081 
NSRunLoop currentRunLoop run.
