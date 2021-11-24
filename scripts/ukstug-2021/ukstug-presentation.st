framework:Slides3D load.  

class ProgramVsSystem : ASCSlide {
   var code.
   var system.
   var problem.
   var tools.
   var shapeGroup.

   -<void>setupSlideWithPresentationViewController:controller {
       self textManager setTitle:'Static Program Text vs. Dynamic Execution'.
       self textManager addBullet:'FORTRAN' atLevel:0.
       shapeGroup := SCNNode node.
       self setShapeGroup:shapeGroup.
       self rootNode addChildNode:shapeGroup.
       boxer := ASCBoxMaker new.
       boxer setP: ( -8 @ 0.2 ).
       boxer setColor: (NSColor colorWithDeviceRed:105 / 255.0 green:145.0 / 255.0 blue:14.0 / 255.0 alpha:1 ).  
       boxer setPosition: 0@0 .
       boxer setHeight:120. 
       boxer setYHeight:1.5. 
       boxer setPadding:10. 
       code :=  boxer box:'Code' width:160.
       self setCode:code.
       boxer setPadding:20. 

       system := boxer  box:'System' width:160 color:(NSColor blueColor).
       self setSystem:system.

       problem := boxer box:'Problem' width:160 color:(NSColor redColor).
       self setProblem: problem.

       shapeGroup do addChildNode: #( code, system, problem ) each.
 
   }

   -<int>numberOfSteps {  8. }
 
   -<void>presentStepIndex:<int>index withPresentionViewController:controller {
         index = 0 ifTrue:{ 
            SCNTransaction setAnimationDuration:1.5.
         }.
         index = 1 ifTrue:{ 
            SCNTransaction begin.
            self textManager addBullet:'Non-Computation' atLevel:0.
            self problem setXYPosition: -3.0  @ 0.20 .
            SCNTransaction commit.
         }.
           index = 2 ifTrue:{ 
            SCNTransaction begin.
            self textManager addBullet:'OOP' atLevel:0.
            self system setXYPosition: -3.0 @ 0.20 .
            SCNTransaction commit.
         }.
       index = 3 ifTrue:{
            SCNTransaction begin.
            self textManager addBullet:'Ruby' atLevel:0.
            self code setXYPosition: -14.0  @ 0.20 .
            SCNTransaction commit.
         }.
       index = 4 ifTrue:{
            SCNTransaction begin.
            self code setXYPosition: -8.0  @ 0.20 .
            SCNTransaction commit.
         }.
       index = 5 ifTrue:{
            SCNTransaction begin.
            self textManager addBullet:'FP' atLevel:0.
            self system setXYPosition: -8.0  @ 0.20 .
            SCNTransaction commit.
         }.
         index = 6 ifTrue:{
            SCNTransaction begin.
            self system setXYPosition: -3.0  @ 0.20 .
            SCNTransaction commit.
         }.
         index = 7 ifTrue:{
            SCNTransaction begin.
            self textManager addBullet:'Objective-Smalltalk' atLevel:0.
            self code setXYPosition: -3.0  @ 0.20 .
            SCNTransaction commit.
         }.
   }
}
         
    
    
class ImageSlide : ASCSlide { 
     var text.
     var image.
     var imageURL.
     var imageScale.
     var xOffset.
     -<void>setupSlideWithPresentationViewController:controller {
       self textManager setTitle:self text.
       shapeGroup := SCNNode node.
       self rootNode addChildNode:shapeGroup.
       image := NSImage alloc initWithContentsOfFile:self imageURL.
       size := image size.
       size := size * self imageScale .
       boxer := ASCBoxMaker new.
       boxer setP: ( (self xOffset - 8 ) @ 0.2 ).
       boxer setColor: (NSColor grayColor).  
       boxer setPosition: 0@0 .
       boxer setHeight: size y. 
       boxer setYHeight:1.5. 
       boxer setPadding:10. 
       imageBox :=  boxer box:'' width: size x.
       imageBox geometry materials firstObject diffuse setContents: image.
       shapeGroup addChildNode: imageBox.
     }
}

  

controller := #ASCPresentationViewController{
    #Name: 'UKSTUG Demo'.
    #Slides: #(

      #ASCChapterSlide { 
               #text: 'Objective-S',
               #subtitle: 'Marcel Weiher (@mpweiher)',
         }  ,

        #ASCBulletSlide{ 
             #title: 'Objective-S in a nutshell',
             #bullets: #( 
               'Architecture-oriented',
               'Smalltalk-inspired (generalised)',
               'Embeddable framework',
               'VM-less, Objective-C, interpreter, (native ompiler)',
             )
        } ,

        #ASCBulletSlide{ 
             #title: 'Fahrplan',
             #bullets: #( 
               'Inspiration (top-down + bottom up)',
               'Why software architecture?',
               'Objective-S overview',
               'Demos',
              )
        } ,

        #ASCBulletSlide{ 
             #title: 'Software seems Large and Complicated...',
             #bullets: #( 
                '...for what it does – Alan Kay',
                'MS Office: 400 MLOC',
                'Wunderlist: 180 KLOX',
                'You''re gonna need a larger room',
           )
        } ,
        #ASCBulletSlide{ 
             #title: 'Architectural Mismatch',
             #bullets: #( 
                'General Purpose or ALGOrithmic Languages?',
                'Chatty: Software = Algorithms + Data Structures + Architecture',
                'Languages are mismatched with GUI programming',
             )
        } ,

      #ASCChapterSlide { 
               #text: 'Why Software Architecture?',
               #subtitle: 'Objective-S',
         }  ,
        #ASCBulletSlide{ 
             #title: 'OO',
             #bullets: #( 
                '"I didn''t have C++ in mind"',
                '"Much the same applies to Smalltalk"',
                'We can build, but we cannot express',
                'The program is a meta-description',
             )
        } ,

        #ASCBulletSlide{ 
             #title: 'Architecture',
             #bullets: #( 
                'ma',
                'We need lots of different kind of glue',
                'Procedures are the Assembly Language of Module Interconnect',
                'Architectural Description Languages',
                'Why only describe?',
             )
        } ,
        #ASCBulletSlide{ 
             #title: 'Better architecture comes with friction ',
             #bullets: #( 
                'In-Process REST (BBC)',
                'Polymorphic Write Streams',
                'Storage Combinators',
             )
        } ,

      #ASCChapterSlide { 
               #text: 'Overview',
               #subtitle: 'Objective-S',
         }  ,

        #ASCBulletSlide{ 
             #title: 'Ovreview',
             #bullets: #( 
                'Smalltalk with syntax (changes)',
                'Polymorphic Identifiers',
                'Storage Combinators',
                'Complex object literals',
                'Polymorphic Write Streams',
                'Higher Order Messaging',
             )
        } ,
        #ASCBulletSlide{ 
             #title: 'Smalltalk changes',
             #bullets: #( 
                'Full file syntax',
                'Curly braces',
                'Message chaining with pipe',
             )
        } ,

      #ASCChapterSlide { 
               #text: 'Demo',
               #subtitle: 'Objective-S basics',
         }  ,

        #ASCBulletSlide{ 
             #title: 'Polymorphic Identifers',
             #bullets: #( 
                'Identifiers are URIs',
                'Resolved dynamically',
                'Parameterized',
             )
        } ,

      #ASCChapterSlide { 
               #text: 'Demo',
               #subtitle: 'Polymorphic Identiifers',
         }  ,


 
    #ImageSlide{ 
               #text: 'Async Writer' ,
               #imageURL: '/Users/marcel/Documents/Writing/Dissertation/Papers/StorageCombinators/async-writer.png' ,
               #xOffset: 2.0 ,
               #imageScale: 0.6 ,
         }  , 
 
       )
}.
                         
 
controller view openInWindow:'Objective-SmallTalk (UKSTUG 2021)'.  

controller     
    

controller goToSlideAtIndex:0    
