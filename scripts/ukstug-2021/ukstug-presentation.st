framework:Slides3D load.    

    
    
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
               'Examples',
              )
        } ,

        #ASCBulletSlide{ 
             #title: 'Software seems Large and Complicated...',
             #bullets: #( 
                '...for what it does – Alan Kay',
                'MS Office: 400 MLOC',
                'Wunderlist: 180 KLOC',
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
             #title: 'Why not (just) OO?',
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
             #title: 'Brief intro to Software Architecture',
             #bullets: #( 
                'Components, connectors, systems',
                'Components have ports',
                'Connectors have roles',
                'Styles are classes of systems',
                'component.port → role.connector.role → port.component',
             )
        } ,
        #ASCBulletSlide{ 
             #title: 'Better architecture comes with friction ',
             #bullets: #( 
                'In-Process REST (BBC)',
                'Polymorphic Write Streams',
                'Storage Combinators at Wunderlist',
             )
        } ,

      #ASCChapterSlide { 
               #text: 'Overview',
               #subtitle: 'Objective-S',
         }  ,

        #ASCBulletSlide{ 
             #title: 'Objective-S Overview',
             #bullets: #( 
                'Smalltalk with syntax (changes)',
                'Complex object literals',
                'Polymorphic Identifiers',
                'Storage Combinators',
                'Polymorphic Write Streams',
                '→',
             )
        } ,

    #ImageSlide{ 
               #text: 'Async Writer' ,
               #imageURL: '/Users/marcel/Documents/Writing/Dissertation/Papers/StorageCombinators/async-writer.png' ,
               #xOffset: 2.0 ,
               #imageScale: 0.6 ,
         }  , 
 

        #ASCBulletSlide{ 
             #title: 'Demo: Objective-S basics',
             #bullets: #( 
                'Full file syntax',
                'Curly braces',
                'Message chaining with pipe',
             )
        } ,

        #ASCBulletSlide{ 
             #title: 'Demo: Polymorphic Identifers',
             #bullets: #( 
                'Identifiers are URIs',
                'Filesystem and http',
                'Resolved dynamically',
                'Parameterized',
                'ref:',
             )
        } ,


        #ASCBulletSlide{ 
             #title: 'Storage Combinators',
             #bullets: #( 
                'HTTP server',
                'FUSE',
             )
        } ,


        #ASCBulletSlide{ 
             #title: 'Polymorphic Write Streams',
             #bullets: #( 
                'HTTP server',

                'FUSE',
             )
        } ,

     #ASCChapterSlide { 
               #text: 'Examples',
               #subtitle: 'Objective-S',
         }  ,

        #ASCBulletSlide{ 
             #title: 'Examples',
             #bullets: #( 
                'Browsers',
                'Tasks backend',
                'SiteBuilder',
                'ViewBuilder',
             )
        } ,



        )
}.
                         
 
controller view openInWindow:'Objective-SmallTalk (UKSTUG 2021)'.    <NSWindow: 0x11b638190>
    