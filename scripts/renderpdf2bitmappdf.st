framework:EGOS_Cocoa load    

pdf := MPWPDFDocument alloc initWithData: file:/tmp/nightingale.pdf     

drawingContext := MPWCGBitmapContext grayBitmapContext: ( 595 @ 842 ) scale: (600 / 72 ).   


drawingContext fillBackgroundWithColor: (drawingContext colorGray: 1.0 alpha:1.0).  
pdf drawCGPageNo:0 onContext: drawingContext.      

file:/tmp/page1.png  := drawingContext image representationUsingType: 4 properties: #{}      