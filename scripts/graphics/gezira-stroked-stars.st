#!env stui
#-<void>gezira
framework:Gezira load.

class  MyStar : GeziraShape
{
  var penWidth.
  var penCap.
  var miterLimit.
  -initWithCoords:coords windowSize:size
  {
    self ← super init.
    this:x ← 0 to: size x | random.
    this:y ← 0 to: size y | random.
    this:dy ← 0.5 to: 3.0  | random.
    this:scale ← 0.1 to: 0.5 | random.
    this:angle ← 0 to: 300 | random.
    this:dangle ← -0.5 to: 0.5 | random.
    this:windowSize ← size.
    this:penWidth ← 5.
    this:miterLimit ← 4.
    this:penCap ← -1.
    this:color ← NSColor colorWithRed:(0.0 to: 1.0 | random)
                                green:(0.0 to: 1.0 | random)
                                 blue:(0.0 to: 1.0 | random)
                                alpha: 0.8.
 
    this:coords ← coords.
    self.
  }
  -<void>renderWithParent:parent on:bitmap {
     transform ← MPWTransformBeziers stream.
     transform setMatrix: self transformationMatrix.
     filters ← [
         (parent strokeBezierWidth: this:penWidth miterLimit: this:miterLimit cap: this:penCap),
         (parent clipToSize: this:windowSize),
	 transform,
         (parent clipToSize: bitmap pixelsWide @ bitmap pixelsHigh),
         (parent rasterize),
         (parent compositorImage: bitmap color: this:color ),
     ].
     pipeline ← parent pipeline:filters.
     pipeline writeObject: self coords.
  }

  -transformationMatrix {

    var m.
    m ← MPWMatrix matrixIdentity.
    m ← m matrixTranslatedBy: this:x y: this:y.
    m ← m matrixRotatedBy: this:angle.
    m ← m matrixScaledBy: this:scale.
    m ← m matrixTranslatedBy:-250 y:-250.
    m.
   }
}.
coords ← #MPWRealArray[ 
    250.00000, 150.00000, 237.65650, 183.01064, 225.31301, 216.02128,
    225.31301, 216.02128, 190.10368, 217.55979, 154.89434, 219.09830,
    154.89434, 219.09830, 182.47498, 241.03850, 210.05562, 262.97871,
    210.05562, 262.97871, 200.63855, 296.94020, 191.22147, 330.90169,
    191.22147, 330.90169, 220.61073, 311.45084, 250.00000, 292.00000,
    250.00000, 292.00000, 279.38926, 311.45084, 308.77852, 330.90169,
    308.77852, 330.90169, 299.36144, 296.94020, 289.94437, 262.97871,
    289.94437, 262.97871, 317.52501, 241.03850, 345.10565, 219.09830,
    345.10565, 219.09830, 309.89631, 217.55979, 274.68698, 216.02128,
    274.68698, 216.02128, 262.34349, 183.01064, 250.00000, 150.00000,
].


demo ← #StrokeDemo{ numberOfShapes: 100, shapeCoords: coords, shapeClass: class:MyStar  }.
view ← #NSImageView{ frame: (400@400) }.
window ← view openInWindow:'Gezira'.
demo run:view.
shell runInteractiveLoop.
