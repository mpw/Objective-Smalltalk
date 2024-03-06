framework:Slides3D load.     


 
controller := #ASCPresentationViewController{
    Name: 'HPI Demo'.
    Slides: [

      #ASCChapterSlide { 
               text: 'Objective-S',
               subtitle: 'Marcel Weiher (@mpweiher)'
         }  ,

      #ASCBulletSlide{ 
             title: 'Objective-S',
             bullets: [
                'Software Architecturual Programming (Language)',
                'Generalizes Smalltalk',
                'Objective-C framework (peer/interop)',
             ]
        } ,
       #ASCChapterSlide { 
               text: 'Motivation',
               subtitle: 'Objective-S'
         }    ,


        #ASCBulletSlide{ 
             title: 'Motivation',
             bullets:  [
                'Too much code',
                'OO is still too ALGOL → Architectural Mismatch',
             ]
        } ,
        #ASCBulletSlide{ 
             title: 'Approach',
             bullets: [
                'Alan Kay: figure out the metasystem',
                'Unicon:  connectors ←→ programming language metaystem',
                'ST: decouple class hiearchy from implementation hierarchy',
                '→ metasystem: conceptual class hierarchy of connectors',
             ]
        } ,

       #ASCChapterSlide{ 
               subtitle: 'Objective-SmallTalk',
               text: 'Approach'
         } ,



       #ASCBulletSlide{ 
             title: 'Objective-SmallTalk: Approach',
             bullets: [
                'Implement different architectural styles',
                'Add language support',
                'Inform the metasystem',
             ]
        }  ,

       #ASCBulletSlide{ 
             title: 'Architectural Styles',
             bullets: [
                'Objects and Messages',
                'Pipes and Filters',
                'Implicit Invocation',
                '(In-process) REST',
             ]
        } ,

       #ASCSlideWithFigure{ 
             delayInSeconds: 5.0.
             title: 'Objects and Messages',
             bullets: [
                'Objective-C compatible semantics',
                'Interpreted and native-compiled',
                '"C" using type annotations',
                'Higher Order Messaging',
                'Framework-oriented development',
                'Full platform integration',
             ]
        } ,
  

       #ASCBulletSlide{ 
             title: 'Pipes and Filters',
             bullets: [
                'Polymorphic Write Streams (DLS ''19)',
                '#writeObject:anObject',
                'Triple Dispatch + Message chaining',
                'Asynchrony-agnostic',
                'Streaming / de-materialized objects',
                'Serialisation, PDF/PS (Squeak), Wunderlist, MS , To Do',
                'Outlook: filters generalise methods?',
            ]
        } ,
       #ASCBulletSlide{ 
             title: 'Implicit Invocation',
             bullets: [ 
                'Notification Protocols',
                'Class adopts a Protocol to register for notifications',
             ]
        } ,

       #ASCBulletSlide{ 
             title: 'In-Process REST',
             bullets: [
                'What real large-scale networks use',
                'Polymorphic Identifiers',
                'Stores',
                'Storage Combinators',
                'Used in a number of applications',
             ]
        } ,




       #ASCBulletSlide{ 
             title: 'Polymorphic Identifiers',
             bullets: [
                'All identifiers are URIs',
                "var:hello := 'World!",
                'file:{env:HOME}/Downloads/site := http://objective.st',
                'slider setValueHolder: ref:var:celsius',
             ]
        } ,

       #ASCBulletSlide{ 
             title: 'Stores',
             bullets: [ 
                'PIs are evaluated via stores',
                'Like in-process REST servers',
                'Or composable dictionaries',
                'var:hello <-> (schemes at:''var'') at:''hello''',
             ]
        }  ,
       #ASCBulletSlide{ 
             title: 'Example Stores',
             bullets: [
                'Local variables, environment variables',
                'Filesystems, HTTP',
                'Databases: SQL/SQLite',
                'Other applications (via Apple Events)',
                'etc.',
             ]
        }  ,

       #ASCBulletSlide{ 
             title: 'Storage Combinators',
             bullets: [ 
                'Onward! ''19',
                'Combinator exposes + consumes REST interfaces',
                'Uniform interface (REST) enables pluggability',
                'Narrow, semantically tight interface enables intermediaries',
                '10x productivity/code improvments',
             ]
        } ,


      #ASCImageSlide{ 
               text: 'Simple Composed Store',
               imagePath: '/Users/marcel/Documents/Writing/Dissertation/Papers/StorageCombinators/disk-cache-json-aligned.png',
               xOffset: 2.0 ,
               imageScale: 0.8
         }  , 
    #ASCImageSlide{ 
               text: 'Async Writer',
               imagePath: '/Users/marcel/Documents/Writing/Dissertation/Papers/StorageCombinators/async-writer.png',
               xOffset: 2.0 ,
               imageScale: 0.6
         }  , 
      #ASCImageSlide{ 
               text: 'To Do Store Hierarchy',
               imagePath: '/Users/marcel/Documents/Writing/Dissertation/Papers/StorageCombinators/store-hierarchy-intermediate.png',
               xOffset: 2.0 ,
               imageScale: 0.34
         }  , 

       #ASCChapterSlide{ 
               subtitle: 'Objective-SmallTalk',
               text: 'Language Support'
         } ,



       #ASCBulletSlide{ 
             title: 'Language support',
             bullets: [
                'Class, method, protocol syntax',
                'Polymorphic Identifiers',
                'Composition "operator" → ',
                'Permanent Assignment |= ',
                'Stores and Filters as class templates',
                'Property Paths',
             ]
        }  ,

       #ASCChapterSlide{ 
               subtitle: 'Objective-SmallTalk',
               text: 'Demo'
         } ,
       #ASCChapterSlide{ 
               subtitle: 'Objective-SmallTalk',
               text: 'Metasystem'
         } ,
      #ASCBulletSlide{ 
             title: 'Metasystem',
             bullets: [
                'Apply/Eval → Connect/Run',
                'Class is subclass of Component',
                'Message, Interface etc. subclasses of Connector',
                'Components have ports, connectors roles',
             ]
        }  ,

       #ASCChapterSlide{ 
               subtitle: 'Objective-SmallTalk',
               text: 'Outlook'
         } ,

      #ASCBulletSlide{ 
             title: 'Outlook',
             bullets: [
                'Port Stores and Polymorphic Write Streams',
                'Documentation / Sample Code',
                'Improve native compiler',
                'Tooling (Debugger)',
                'You! (http://objective.st)',
             ]
        }  ,

      #ASCChapterSlide { 
               text: 'Q&A   http://objective.st',
               subtitle: 'Marcel Weiher (@mpweiher)'
         }  ,


       ]
}. 
                  
  
controller view openInWindow:'Objective-SmallTalk (HPI 2024)'.   <NSWindow: 0x10fc0a340>

      
 
file:/tmp/lastpage.tiff := (controller view snapshot)  

controller view frame   



controller     
    

controller goToSlideAtIndex:0    
