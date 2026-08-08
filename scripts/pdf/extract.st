#!env st
#-convert: <ref>file
framework:EGOS load.
framework:EGOS_Cocoa load.

class TextDumper : MPWGraphicDumper
{
   var lastY:int.

   -<void>writeText:text withGstate:gstate {
      var newY:int ← gstate ctm objectAtIndex:5 | intValue.
      newY = this:lastY ifFalse: {
	stdout println:''.
        this:lastY ← newY.
      }.
      stdout print:text.
      stdout print:' '.
   }
}.


data ← file value.
stdout println: data length.
pdf ← MPWPDFFile alloc initWithPdfData: file value .
pdf graphicsInterpreter setTarget: #TextDumper{}.
shell runInteractiveLoop.
