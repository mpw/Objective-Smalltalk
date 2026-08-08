#!env st
#-scenesFor: character
framework:EGOS load.
framework:EGOS_Cocoa load.

class TextDumper : MPWGraphicDumper
{
   var lastY:int.
   var line:String.
   var scene:String.
   var scenes:NSOrderedSet.
   var character:String.
       
   -initWithTarget:aTarget {
      self ← super initWithTarget:aTarget.
      this:line ← ''.
      this:scenes ← NSMutableOrderedSet new.
      this:scene ← ''.
      self.
   }

   -<void>writeText:text withGstate:gstate {
      var newY:int ← gstate ctm objectAtIndex:5 | intValue.
      newY = this:lastY ifFalse: {
        (this:line containsString:'Scene ' ) ifTrue:{
           this:scene ← this:line.
        }.
        (this:line containsString: this:character) ifTrue:{
	   this:scenes addObject: this:scene.
        }.
        this:lastY ← newY.
        this:line ← ''.
      }.
      this:line ← this:line , text.
   }
}.


pdf ← MPWPDFFile alloc initWithPdfData: file:libretto.pdf .
sceneLister ← #TextDumper{ target: stdout, character: character }.
pdf graphicsInterpreter setTarget: sceneLister.
0 to: pdf pageCount - 1 do: { :i  | 
   pdf renderPageNo:i.
}.
stdout println: sceneLister character.
stdout println: sceneLister scenes.
