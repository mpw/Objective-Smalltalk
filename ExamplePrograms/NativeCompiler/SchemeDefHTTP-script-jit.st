#!env st
framework:ObjectiveHTTPD load.
framework:ObjSTNative load.
scheme Hello 
{
   /hi {
      get { 
	'Simple GET Property Path without parameters'.
     }
   }
   -fib:n {
       n < 2 ifTrue:{ n. } ifFalse: { (self fib: n - 1 ) + (self fib: n -2 ). }.
   }
	
   /hi/:p1 {
      get { 
	self fib:p1 intValue.
     }
   }
}

jit := STNativeCompiler jitCompiler.
methodStore := shell evaluator methodStore classes at:'Hello' | methodCallbacks 
callback := methodStore at:'fib:'.
method := callback method.
#jit compileAndAddMethod:method forClassNamed:'Hello'.
Hello scheme serveOnPort: 8081 
NSRunLoop currentRunLoop run.
