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
   -<void>writeOnLineProcessor:aProcessor {
      aProcessor writeLine:self.
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
       this:target do !  sorted each.
       this:pageLines ← NSMutableArray array.

   }
}.

filter LineProcessor : MPWFlattenStream {
   -<SEL>streamWriterMessage
   {
      'writeOnLineProcessor:' 
   }
   -<void>writeLine: aLine:Line {
      this:target ! aLine.
   }
}.

filter SceneExtractor : LineProcessor {
   var scene:String.
   var emit.
   -initWithTarget:aTarget {
      self ← super initWithTarget:aTarget.
      this:emit ← false.
      this:scene ← ''.
      self.
   }
   -<void>writeLine:aLine { 
      var text ← aLine text.
      (text containsString:'Scene ' ) ifTrue: {
	 (text containsString: this:scene) ifTrue: { 
            this:emit ← true.
         } ifFalse: {
            this:emit ← false.
         }.
      }.
      this:emit ifTrue: { this:target ! aLine }.
   }
}.


filter WhiteSpaceRemover : LineProcessor {
     -<void>writeLine:aLine {
         var str:String ← aLine text.
         { str hasSuffix:' '} whileTrue: {
              str ← str substringToIndex: str length - 1.
         }.
         aLine setText:str.
         this:target ! aLine.
     }

}

extension NSObject {
    -<void>writeOnLineProcessor:aProcessor {
        self flattenOntoStream: aProcessor.
    }

}.


pdf ← MPWPDFFile alloc initWithPdfData: file value .
scenes ← #SceneExtractor{  scene: 'Scene Three' }.
space ← #WhiteSpaceRemover{} 
scenes → space → stdline.
writer ← #TextDumper{ target: scenes }.
pdf graphicsInterpreter setTarget: writer.
0 to: pdf pageCount - 1 do: { :i  | 
   var pageNo ← i+1.
   stdout println:"===== page {pageNo} ====".
   pdf renderPageNo:i.
   writer processPage.
}.
