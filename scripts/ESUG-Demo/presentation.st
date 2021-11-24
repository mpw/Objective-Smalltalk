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
    #Name : 'ESUG Demo'.
    #Slides : #(

      #ASCChapterSlide { 
               #text : 'Objective-SmallTalk'.
               #subtitle : 'Marcel Weiher (@mpweiher)'
         }  ,

        #ASCBulletSlide{ 
             #title : 'Objective-SmallTalk'.
             #bullets : #( 
                'Embeddable SmallTalk language (Mac, iOS, Linux, Windows)',
                'Objective-C framework (peer/interop)',
                'Generalizes Objects+Messages to Components+Connectors',
                'Enable composition by solving Architectural Mismatch',
             )
        } ,
       #ASCChapterSlide { 
               #text : 'Architectural Mismatch'.
               #subtitle : 'Objective-SmallTalk'
         }    ,


        #ASCBulletSlide{ 
             #title : 'Architectural Mismatch'.
             #bullets : #( 
                'Packaging mismatch',
                'Interactive programs vs. programming languages',
                'Programs vs. Systems, Computers do not compute',
             )
        } ,
        #ASCBulletSlide{ 
             #title : 'Packaging Mismatch'.
             #bullets : #( 
                'Garlan et al (''95)',
                'Functionality available but not accessible',
                'Who has the thread of control?',
                '→ Minimize assumptions',
                '→ (see also: Hexagonal, Ports/Adaptors, Naked Objects)',
             )
        } ,
        #ASCBulletSlide{ 
             #title : 'Interactive Programs'.
             #bullets : #( 
                '"Programs = Algorithms + Data Structurs + Architecture"',
                'y = f(x)    v.   interactive programs',
                'Transformational v. reactive',
                'Temperature Converter Example (Modularity ''16)',
             )
        } ,
       #ASCBulletSlide{ 
             #title : 'The Gentle Tyranny of Call/Return'.
             #bullets : #( 
                'Feymnan: we name everything just a little wrong',
                'Multiparadigm: Procedural, OO and FP!',
                "Guy Steele: it's no longer about completion",
                "Oscar Nierstrasz: we were told we could just model the domain",
                "Andrew Black: good OO students antropmorphise the objects",
             )
        } ,

         #ProgramVsSystem { 
              #lightIntensities : #( 0.2 , 0.7 )
              
         }  ,

       #ASCBulletSlide{ 
             #title : 'Solution Ideas'.
             #bullets : #( 
                'Alan Kay: figure out the metasystem',
                'Unicon:  connectors ←→ programming language metaystem',
                'ST: decouple class hiearchy from implementation hierarchy',
                '→ metasystem: conceptual class hierarchy of connectors',
             )
        } ,

       #ASCChapterSlide{ 
               #subtitle : 'Objective-SmallTalk'.
               #text : 'Approach'
         } ,



       #ASCBulletSlide{ 
             #title : 'Objective-SmallTalk: Approach'.
             #bullets : #( 
                'Implement different architectural styles',
                'Add language support',
                'Inform the metasystem',
             )
        }  ,

       #ASCBulletSlide{ 
             #title : 'Architectural Styles'.
             #bullets : #( 
                'Objects and Messages',
                'Pipes and Filters',
                'Implicit Invocation',
                '(In-process) REST',
             )
        } ,

       #ASCSlideWithFigure{ 
             #delayInSeconds : 5.0.
             #title : 'Objects and Messages'.
             #bullets : #( 
                'Objective-C compatible semantics',
                'Interpreted and native-compiled',
                '"C" using type annotations',
                'Higher Order Messaging',
                'Framework-oriented development',
                'Full platform integration',
             )
        } ,
  

       #ASCBulletSlide{ 
             #title : 'Pipes and Filters'.
             #bullets : #( 
                'Polymorphic Write Streams (DLS ''19)',
                '#writeObject:anObject',
                'Triple Dispatch + Message chaining',
                'Asynchrony-agnostic',
                'Streaming / de-materialized objects',
                'Serialisation, PDF/PS (Squeak), Wunderlist, MS , To Do',
                'Outlook: filters generalise methods?',
            )
        } ,
       #ASCBulletSlide{ 
             #title : 'Implicit Invocation'.
             #bullets : #( 
                'Notification Protocols',
                'Class adopts a Protocol to register for notifications',
             )
        } ,

       #ASCBulletSlide{ 
             #title : 'In-Process REST'.
             #bullets : #( 
                'What real large-scale networks use',
                'Polymorphic Identifiers',
                'Stores',
                'Storage Combinators',
                'Used in a number of applications',
             )
        } ,


       #ASCBulletSlide{ 
             #title : 'Polymorphic Identifiers'.
             #bullets : #( 
                'All identifiers are URIs',
                "var:hello := 'World!",
                'file:{env:HOME}/Downloads/site := http://objective.st',
                'slider setValueHolder: ref:var:celsius',
             )
        } ,

       #ASCBulletSlide{ 
             #title : 'Stores'.
             #bullets : #( 
                'PIs are evaluated via stores',
                'Like in-process REST servers',
                'Or composable dictionaries',
                'var:hello <-> (schemes at:''var'') at:''hello''',
             )
        }  ,
       #ASCBulletSlide{ 
             #title : 'Example Stores'.
             #bullets : #( 
                'Local variables, environment variables',
                'Filesystems, HTTP',
                'Databases: SQL/SQLite',
                'Other applications (via Apple Events)',
                'etc.',
             )
        }  ,

       #ASCBulletSlide{ 
             #title : 'Storage Combinators'.
             #bullets : #( 
                'Onward! ''19',
                'Combinator exposes + consumes REST interfaces',
                'Uniform interface (REST) enables pluggability',
                'Narrow, semantically tight interface enables intermediaries',
                '10x productivity/code improvments',
             )
        } ,


      #ImageSlide{ 
               #text : 'Simple Composed Store'.
               #imageURL : '/Users/marcel/Documents/Writing/Dissertation/Papers/StorageCombinators/disk-cache-json-aligned.png'.
               #xOffset : 2.0 .
               #imageScale : 0.8
         }  , 
    #ImageSlide{ 
               #text : 'Async Writer'.
               #imageURL : '/Users/marcel/Documents/Writing/Dissertation/Papers/StorageCombinators/async-writer.png'.
               #xOffset : 2.0 .
               #imageScale : 0.6
         }  , 
      #ImageSlide{ 
               #text : 'To Do Store Hierarchy'.
               #imageURL : '/Users/marcel/Documents/Writing/Dissertation/Papers/StorageCombinators/store-hierarchy-intermediate.png'.
               #xOffset : 2.0 .
               #imageScale : 0.34
         }  , 

       #ASCChapterSlide{ 
               #subtitle : 'Objective-SmallTalk'.
               #text : 'Language Support'
         } ,



       #ASCBulletSlide{ 
             #title : 'Language support'.
             #bullets : #( 
                'Class, method, protocol syntax',
                'Polymorphic Identifiers',
                'Composition "operator" → ',
                'Permanent Assignment |= ',
                'Stores and Filters as class templates',
                'Property Paths',
             )
        }  ,

       #ASCChapterSlide{ 
               #subtitle : 'Objective-SmallTalk'.
               #text : 'Demo'
         } ,
       #ASCChapterSlide{ 
               #subtitle : 'Objective-SmallTalk'.
               #text : 'Metasystem'
         } ,
      #ASCBulletSlide{ 
             #title : 'Metasystem'.
             #bullets : #( 
                'Apply/Eval → Connect/Run',
                'Class is subclass of Component',
                'Message, Interface etc. subclasses of Connector',
                'Components have ports, connectors roles',
             )
        }  ,

       #ASCChapterSlide{ 
               #subtitle : 'Objective-SmallTalk'.
               #text : 'Outlook'
         } ,

      #ASCBulletSlide{ 
             #title : 'Outlook'.
             #bullets : #( 
                'Port Stores and Polymorphic Write Streams',
                'Documentation / Sample Code',
                'Improve native compiler',
                'Tooling (Debugger)',
                'You! (http://objective.st)',
             )
        }  ,


      #ASCChapterSlide { 
               #text : 'Q&A   http://objective.st'.
               #subtitle : 'Marcel Weiher (@mpweiher)'
         }  ,
      )
} 
                       
 
controller view openInWindow:'Objective-SmallTalk (ESUG 2019)'. 
 
file:/tmp/lastpage.tiff := (controller view snapshot)  

controller view frame   



controller     
    

controller goToSlideAtIndex:0    
