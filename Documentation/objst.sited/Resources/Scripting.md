Scripting
=======

Objective-Smalltalk has been carefully designed to remove barriers between scripts
and programs, to the point of making the differences disappear.  Scripts have
direct access to the full power of the system frameworks, and methods written
in Objective-Smalltalk have all the power of a scripting language.


In-App Scripting
---------------------

Most of Objective-Smalltalk comes as a framework, and can therefore be added to
an application by linking in the framework.  

	[MPWSmalltalkCompiler runScript:'a := 3+4'];


It is also easy to add methods to classes, and there is a *MethodServer* 
that enables loading classes into a running process via HTTP.  

As one example, the [BookLightning](http://www.metaobject.com/Products/) imposition 
program uses embedded Objective-Smalltalk scripts to control the actual imposition process.

    class ScriptedQuartoBookMaker : QuartoBookMaker
    {

     -<void>drawOutputPage:<int>pageNo  {
        isBackPage := (( pageNo / 2 ) intValue ) isEqual: (pageNo / 2 ).
        pages:=self pageMap objectAtIndex:pageNo.
        page1:=pages integerAtIndex:0.
        page2:=pages integerAtIndex:1.
        self drawPage:page1 andPage:page2 flipped:(self shouldFlipPage:pageNo).
     }

    -<void>drawPage:<int>page1 andPage:<int>page2 flipped:<int>flipped {
       drawingStream := self drawingStream.
       base := MPWPSMatrix matrixRotate:-90.

       drawingStream saveGraphicsState.
       flipped ifFalse: {
           flipped := NSUserDefaults standardUserDefaults boolForKey:'flip' .
       }.
       flipped ifTrue: { drawingStream concat:self flipMatrix }.

       width := self inRect x.

       self drawPage:page1 transformedBy:(base matrixTranslatedBy: (width * -2) y:0).
       self drawPage:page2 transformedBy:(base matrixTranslatedBy: (width * -1) y:0).

       drawingStream restoreGraphicsState.
     }
    }.
`


Unix Scripting
-------------------

Objective-Smalltalk comes with a Unix REPL called `stsh`.  This simple script 
prints the numbers between the two numbers given on the command line:

    #!/usr/local/bin/stsh
    #-<void>from:<int>from to:<int>to
    stdout do println:(from to: to ) each

The method declaration in the second line acts as an architectural adapter,
giving `stsh` enough information about your script to parse and check 
command line arguments, in this case taking the first two parameters
and binding them to the script variables `to` and `from`.

`stsh` also automatically prints the methods return value to `stdout` unless
the method decares a `void` return. 

Scripts have full access to Cocoa classes.  The following script uniques the
arguments passed on the command line via an `NSSet`:

	#!/usr/local/bin/stsh
	#-unique
	(NSSet setWithObjects:args ) allObjects




The `<ref>` type can be used to indicate
file references, for example the *stcat* script just prints out the contents
of the file passed as its first parameter:


    #!/usr/local/bin/stsh
    #-stcat:<ref>file
    file value.

Although the `<ref>` type defaults to files, it can actually pass arbitrary
[URIs](/URIs), so `stcat http://objective.st` will retrieve this web site and
`stcat env:HOME` will print the `$HOME` environment variable.

Web-Scripting
-------------

Objective-Smalltalk makes it easy to interact with web resources.  The following 
example looks up a zip-code using the zipTastic web service.

    #!/usr/local/bin/stsh
    #-zip:zipCode
    ref:http://zip.elevenbasetwo.com getWithArgs zip:zipCode

Web serving is supported using the [Objective-HTTP](https://github.com/mpw/ObjectiveHTTPD)
micro framework.  A trivial *Hello World* server looks as follows:

    #!/usr/local/bin/stsh
    framewok:ObjectiveHTTPD load.
    scheme:site := MPWSiteMap scheme.
    site:/hi := 'Hello World!'.
    (scheme:site -> (MPWSchemeHttpServer serverOnPort:8081)) startHttpd.

After we load the ObjectiveHTTPD framework, we create a *scheme handler* that operates
in memory and hook it up to the URI scheme `site`. We can then set our *Hello World*
literal string directly as the value of `site:/hi` and then start a web-server connected
to that site via the "right arrow" connector.  

As another example, you can serve a specific directory by substituting the in-memory scheme with
a directory reference (that''s converted to a scheme handler implicitly):

    #!/usr/local/bin/stsh
    #-<void>fileserver:<ref>dir
   framewok:ObjectiveHTTPD load.
    (dir -> (MPWSchemeHttpServer serverOnPort:8081)) startHttpd.

Scheme handlers can manage access to objects, respond dynamically by computing values
or combine other scheme handlers.


Apple-Scripting
--------------------

Through use of the scripting bridge, it also becomes easy to control other applications
via Apple Events, for example setting the iChat status message to the current 
iTunes track name.

    app://com.apple.ichat/statusMessage := app://com.apple.itunes/currentTrack/name

This can be used directly from Unix scripts or application code without having to
deal with script strings and try to pass arguments to those scripts via string
processing or other means.  If I want to prefix the current track name, I just
write the code to do it:

	'Listening to ',app://com.apple.itunes/currentTrack/name

(Note that the ScriptinBridge framework and corresponding schema are not loaded 
 into the scripting environment by default, you need to add them by executing
 `scheme:app := MPWScriptingBridgeScheme scheme.`)

