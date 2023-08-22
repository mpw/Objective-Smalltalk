#!env st
class PHPProcessor { 
   var compiler.
   -init {
       super init.
       self setCompiler: STCompiler compiler.
       self.
    }
    -<void>parser:theParser foundProcessingInstructionWithTarget:tag data:d { 
         tag = 'st' ifTrue: { 
           stdout println: (self compiler evaluateScriptString:d).
         } ifFalse: {
           stdout println:'not a st script'.
         }.
     }
}
parser := MPWMAXParser parser
parser setDelegate: PHPProcessor new.
parser parse: file:test.stp 
