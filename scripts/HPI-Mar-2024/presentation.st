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
               subtitle: 'Objective-S',
               text: 'Approach'
         } ,


  
       #ASCSlideWithFigure{ 
             delayInSeconds: 5.0.
             title: 'Approach',
             bullets: [
                'Pipes/Filters',
                'In-Process REST',
                'ST-style OO',
                'Objective-C Framework, platform',
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

       #ASCBulletSlide{ 
             title: 'Language support',
             bullets: [
                'Updated ST + syntax',
                'Polymorphic Identifiers',
                'Property Paths',
                'Object Literals',
                'Connector → ',
                'Permanent Assignment |= ',
             ]
        }  ,

       #ASCChapterSlide{ 
               subtitle: 'Objective-SmallTalk',
               text: 'Demo'
         } ,
       #ASCChapterSlide{ 
               subtitle: 'Objective-SmallTalk',
               text: 'What''s new in 2022-2024'
         } ,
      #ASCBulletSlide{ 
             title: 'News',
             bullets: [
                 'Native Compiler',
                 'STBundle',
                 'GUI',
                 'Cloud/sftp/Dropbox',
                 'Sails',
             ]
        }  ,

       ]
}. 
                  
    
controller view openInWindow:'Objective-S (HPI 2024)'.         <NSWindow: 0x138879c20> 
 
file:/tmp/lastpage.tiff := (controller view snapshot)  

controller view frame   



controller     
    

controller goToSlideAtIndex:0    
