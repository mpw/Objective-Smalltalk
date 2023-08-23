#!env st
#-<void>parsepi:<ref>doc

class PSTProcessor { 
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
parser setDelegate: PSTProcessor new.
parser parse: doc value.
