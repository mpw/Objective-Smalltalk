#!env st
#-<void>convert: <ref>file
framework:EGOS load.
framework:EGOS_Cocoa load.


class Line {
   var x.
   var y.
   var text:String.

   -inRange {
      (this:y < 750) and: (this:y > 52).
   }
   -description {
      "x: {this:x} '{this:text}' y: {this:y}".
   }
   -<int>compare:other {
       other y - this:y.
   }
   -closeTo: y:int {
      (y - this:y) abs < 8.
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
      (this:line closeTo: newY ) ifFalse: {
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
   var pageNo ← i+1.
   stdout println:"===== page {pageNo} ====".
   pdf renderPageNo:i.
   writer processPage.
}.
