#!env st
#-convert: <ref>file
framework:EGOS load.
framework:EGOS_Cocoa load.


class Line {
   var x.
   var y.
   var text:String.

   -<int>inRange {
      (this:y < 750) and: (this:y > 52).
   }
   -description {
      "x: {this:x} '{this:text}' y: {this:y}".
   }
   -<int>compare:other {
       other y - this:y.
   }
}.

class TextDumper : MPWGraphicDumper
{
   var line.
   var pageLines:NSMutableArray.
       
   -initWithTarget:aTarget {
      self ← super initWithTarget:aTarget.
      this:line ← #Line{}.
      this:pageLines ← NSMutableArray array.
      self.
   }

   -<void>writeText:text withGstate:gstate {
      var newY:int ← gstate ctm objectAtIndex:5 | intValue.
      var oldY:int ← this:line y.
      newY = oldY ifFalse: {
        this:line inRange ifTrue: {
             this:pageLines addObject: this:line.
        }.
        this:line ← #Line{ text:'', y: newY, x: (gstate ctm objectAtIndex:4 | intValue) }.
      }.
      this:line setText:  this:line text stringValue , text stringValue.
   }
   -<void>processPage {
       var sorted ← this:pageLines sorted.   
       stdout do println: sorted each.
       this:pageLines ← NSMutableArray array.

   }
}.

pdf ← MPWPDFFile alloc initWithPdfData: file value .
writer ← #TextDumper{ target: stdout }.
pdf graphicsInterpreter setTarget: writer.
0 to: pdf pageCount - 1 do: { :i  | 
   pdf renderPageNo:i.
   writer processPage.
   stdout println:'===== page ===='.
}.
