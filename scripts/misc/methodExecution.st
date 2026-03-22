#!env st
#-runMethod:<int>iterations

class MethodHost {
   -method {
	3.
   }
}

host ← #MethodHost{}.
iterations repeat: {
	host method.
}
