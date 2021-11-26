framework:Slides3D load.  

controller := #ASCPresentationViewController{
    #Name: 'UKSTUG Demo',
    #Slides: #(
       #ASCSlideWithFigure{ 
             #delayInSeconds: 5.0 ,
             #title: 'Implementation',
             #bullets: #( 
                'Objective-C compatible semantics',
                'Interpreted and native-compiled',
                '"C" using type annotations',
                'Framework-oriented development',
                'Full platform integration',
             ),
        }  ,
    )
}.
                        
 
controller view openInWindow:'Objective-S (UKSTUG Mini)'. 
    