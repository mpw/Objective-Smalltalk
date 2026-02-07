Download
==========

Objective-S source code is available on github:

  [https://github.com/mpw/Objective-Smalltalk](https://github.com/mpw/Objective-Smalltalk).  

It requires MPWFoundation, which actually implements much of the architectural components and connectors:

 [https://github.com/mpw/MPWFoundation](https://github.com/mpw/MPWFoundation).

If you want to build the GUI components, including the Smalltalk application, you will also need DrawingContext:

 [https://github.com/mpw/DrawingContext](https://github.com/mpw/DrawingContext).



Build
-----------

The two frameworks are best built together in a workspace.  You can use the one included in Objective-S or use your own.  Building either the Objective-Smalltalk target or one of the sample applications should build everything.



Sample Applications
---------------------------

Objective-S includes a number of sample applications

1. stsh

 A Unix command line interpreter that can be used interactively or for script execution.  In addition to the MPWFoundation and Objective-Smalltalk frameworks, this also requires Stsh.framework, which is part of the Objective-Smalltalk project and built automatically.  

 In order to use, the frameworks must be copied to /Library/Frameworks/ and `stsh` itself to /usr/local/bin/.

 

2. Smalltalk.app

 A very early cut at duplicating small parts of the Smalltalk integrated image experience without 
actually having an image.  Right now, you can open multiple workspaces and a REPL.

 Apart from general exploration and programming tasks, I've also been using the Smalltalk.app 
 together with the [Slides3D](https://github.com/mpw/Slides3D) framework to create [presentations](https://blog.metaobject.com/2019/11/presenting-in-objective-smalltalk.html).

  


Sample Scripts
--------------------

The `scripts` directory in the Objective-Smalltalk project includes a number of example scripts.




