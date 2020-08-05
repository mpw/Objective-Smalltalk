class ObjectiveSTSite : MPWMetaobjectSite
{
-about {
 '
About
=======

The computing world has changed significantly since Objective-C was created
and even more since Smalltalk was released into the wild.
Unix workstations are not
just ubiquitous, we now carry them around in our pockets.  The web 
happened, conceived in Objective-C and born on a NeXT computer. 

Objective-S was created specifically to solve practical problems
that have been encountered in 25 years of Objective-C and Smalltalk use,
but with a theoretical framework that solves many of these problems 
elegantly and minimally, rather than by bolting on special feature after
special feature.


Smalltalk
---------

Objective-S starts off with Smalltalk syntax, which is arguably
still the simplest and most elegant programming language syntax around.

It adds angle brackets for type annotations, both for optional static type
checking and to designate C types such as `<int>` or `<double>` for interoperating
with C and Objective-C.  Generic raw pointers are not supported, wrapper objects
and bulk collections are preferred.

The other syntactic addition to Smalltalk is that identifiers are generalized to
[URIs](/URIs).  This addresses interoperability with the Unix filesystem and Web
Resources, as well as subsuming Objective-C properties and Keyed Value Coding and
making keyed storage such as dictionaries much less necessary and visible.

Objective-C
-----------

Objective-S is built on top of the Objective-C runtime, as a peer to 
Objective-C, and uses the host platform''s C ABI and calling conventions, thus
being fully integrated (e.g. callable) from other peers on the platform.  It
does not require a VM or an image.

Where Objective-C is C with Smalltalk extensions, Objective-Smalltalk is 
Smalltalk with C extensions and the (Objective-)C runtime model.


Software Architecture
----------------------

The basic elements in Objective-S are *components* and *connectors*,
so a message is just a specialization of a connector, as is an assignment.

The basic idea is for custom or higher level connectors to be integrated
as peers to the built in connectors, instead of having to implement
such mechanisms "on top" as is usual.  This should make it possible
to express higher level architectures directly in and as code.

At present, these features are at very early stages.

Another aspect of software architectural support that is more advanced
are the scripting facilities.  Scripting is closely related to 
architectural configuration, for example the Unix shell has been
described as the first architectural description language (ADL).



'.

}
-createTemplater {
    templater := MPWTemplater scheme .
    template := ObjSTSitePage alloc init autorelease.
    template setNavigationNames: self rootLevelNames.
    template setNavigationTargets: self nameToTargetMap.
    templater setTemplate:template .
    templater template setSource:self .
    templater setSourceScheme: self overallRawSite.
    templater.

}
-download {
 '
Source Code
==========

On  [github](https://github.com/mpw/Objective-Smalltalk).  Requires [MPWFoundation](https://github.com/mpw/MPWFoundation).
'.

}
-examples {
 '
Examples
========

You already saw the classic "hello world" on the home page:

    stdout println:''hello world''.

While very simple and a demonstration of basic (Objective-)Smalltalk syntax, it is
slightly atypical in that assumes the `stsh` scripting environment, which predefines
the `stdout` variable as a `ByteStream` that is connected to Unix stdout.  More
scripting examples can be found in [Scripting](/Scripting).

Methods
-------

An `UIAlertViewDelegate` method as used in an educational game ported from Flash:

    -<void>alertView:alertView clickedButtonAtIndex:<int>buttonIndex {
       self newGame.
       self view setNeedsDisplay.
    }

Or a method to refresh the subviews:

    -<void>refreshViews {
        self view subviews do setNeedsDisplay.
    }

An application delegate launching method:

    -<int>application:app didFinishLaunchingWithOptions:optionsDict {
	   self checkICloud.
       self window setRootViewController: self tabBarController. 
       self window makeKeyAndVisible.
       self startEventTap.
       1.
    }

A method that deletes a file and fades out the icon representing that file:

    -<void>deleteFile:filename {
       thumbs := self thumbsView subviews.
       viewsToRemove := thumbs selectWhereValueForKey:''filename'' isEqual:filename.
       aView := viewsToRemove firstObject.

       UIView animateWithDuration:0.4
              animations: { aView setAlpha: 0.0. }
              completion: { aView removeFromSuperview. 
                            UIView animateWithDuration: 0.2
                                   animations: { self thumbsView layoutSubviews. }
                                   completion: { 3 }. 
                          }.
       url := self urlForFile:aFilename.
       NSFileManager defaultManager removeItemAtURL:url  error:nil.
       self thumbsView afterDelay:0.4 | setNeedsLayout.
    }

Blocks become significantly more readable with Smalltalk syntax.

HOM
---

As shown in some of the previous examples, Higher Order Messaging ([HOM](http://en.wikipedia.org/wiki/Higher_order_message))
is fully supported and helps make code more compact and readable.  Take as an example the following code:

    self view subviews do setNeedsDisplay.

This code iterates the `subviews` of the view controllers `view` and sends each one the `setNeedsDisplay` message.  In Objective-C
the code would probably look as follows:

    for ( NSView *aView in [[self view] subviews] ) {
        [aView setNeedsDisplay];
    }
   
While the code is not that much longer, it obscures the central point of the code, the `setNeedsDisplay` message, with the 
machinery for iterating the subviews.


[HOM](https://wikipedia.org/en/Higher_Order_Message.html) support is made more convenient by the fact that literals default to objects.  Here is the code to multiply 
an array of numbers by 5:


    #( 1, 2, 3, 4, 5 ) collect * 5.  ->  ( 5 10 15 25 30 )

Summing an array:

    #( 1, 2, 3, 4, 5 ) reduce + 0.   ->  15

n factorial:

    (1 to: n) reduce * 1.



Site
----

This site was generated by a static site generator based on Objective-S and
Objective-HTTPD.  The root site definition is the following method:



    dynamic:/ := MPWMainPage pageWithStaticContentNamed:''ObjSTMain'' source:self .
    newsplist := rsrc:objst.newsplist value .
    items := MPWProductNewsItem collect newsItemsWithDict:newsplist each site:self.
    dynamic:/ setNewsItems:items.
    dynamic:/ setContentData: self mainPage asData markdownToHtml.
    
    #( ''About'' ''Outlook'' ''Examples'' ''Scripting'' ''URIs'' ''Download'' ) do:[ :name |
        data := (self performSelector:name camelCaseString) asData markdownToHtml.
        dynamic:/{name} := MPWPlainHtmlContent alloc initWithContentData:data.
    ].

This code sets the root page to an instance of `MPWMainPage`, which does some special evaluation and
formatting of news items.  The rest of the pages are filled with HTML created from markdown that is
(at this point) embedded in the code.


'.



}
-mainPage {
 '
Objective-S
==============

Objective-S: software development for the 21st century now with real source code in individual files!



Hello World!
---------------


    stdout println:''hello world''.



'.



}
-outlook {
 '
Outlook
======


- Get native compilation working again
- Improvements to current implementation (better parser, for example)
- Improve tooling
- More work on the software architectural aspects, next up flow-based programming

Pull requests welcome!

'.

}
-overallRawSite {
scheme:markdown cachedBy:scheme:dynamic.

}
-publications {
' List of publications goes here.'

}
-rootLevelNames {
 #( 'Home', 'About', 'Examples',  'Scripting', 'URIs', 'Outlook', 'Publications' , 'Download' )
}
-scripting {
 '
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

	[MPWSmalltalkCompiler runScript:''a := 3+4 ''];


It is also easy to add methods to classes, and there is a *MethodServer* 
that enables loading classes into a running process via HTTP.  


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

As we just saw, Objective-Smalltalk makes it easy to interact with web resources.  The following 
example looks up a zip-code using the zipTastic web service.

    #!/usr/local/bin/stsh
    #-zip:zipCode
    ref:http://zip.elevenbasetwo.com getWithArgs zip:zipCode

Web serving is supported using the [Objective-HTTP](https://github.com/mpw/ObjectiveHTTPD)
micro framework.  A trivial *Hello World* server looks as follows:

    #!/usr/local/bin/stsh
    context loadFramework:''ObjectiveHTTPD''.
    scheme:site := MPWSiteMap scheme.
    site:/hi := ''Hello World!''.
    (scheme:site -> (MPWSchemeHttpServer serverOnPort:8081)) startHttpd.

After we load the ObjectiveHTTPD framework, we create a *scheme handler* that operates
in memory and hook it up to the URI scheme `site`. We can then set our *Hello World*
literal string directly as the value of `site:/hi` and then start a web-server connected
to that site via the "right arrow" connector.  While quite different in terms of what happens, overall code
length and complexity is similar to the Ruby [Sinatra](http://www.sinatrarb.com) micro
framework''s hello world example:

    #!/usr/bin/ruby
    require ''sinatra''

    get ''/hi'' do
       "Hello World!"
    end

The major difference is that whereas most web frameworks expect you to plug your data
model into the framework''s concept of web-serving, `MPWSchemeHttpServer` only acts as
a thin bridge that serves the contents of a *scheme sever* (see [URIs](/URIs)).  For
example, you can serve a specific directory by substituting the in-memory scheme with
a directory reference (that''s converted to a scheme handler implicitly):

    #!/usr/local/bin/stsh
    #-<void>fileserver:<ref>dir
    context loadFramework:''ObjectiveHTTPD''.
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

	''Listening to '',app://com.apple.itunes/currentTrack/name

(Note that the ScriptinBridge framework and corresponding schema are not loaded 
 into the scripting environment by default, you need to add them by executing
 `scheme:app := MPWScriptingBridgeScheme scheme.`)
'.

}
-<void>setupSite {


dynamic:/ := MPWMainPage pageWithStaticContentNamed:'ObjSTMain' source:self .
dynamic:/ setNewsItems: ( MPWProductNewsItem collect newsItemsWithDict: ( rsrc:objst.newsplist value  ) each site:self ) .
dynamic:/ setContentData: self mainPage asData markdownToHtml.


#( 'About', 'Outlook', 'Examples', 'Scripting', 'URIs', 'Publications' , 'Download' ) do:[ :name |
    dynamic:/{name} :=  MPWPlainHtmlContent alloc initWithContentData:(self performSelector:name camelCaseString) asData markdownToHtml
].
image := rsrc:objst.png.
r := MPWResource new.
r setMIMEType:'image/png'.
r setRawData:image. 
dynamic:objst.png := r.




}
-uris {
 '
URIs
====

If you''ve looked at some of the samples, you may have noticed that Objective-Smalltalk fully supports
direct use of URIs in program text.  In fact, all identifiers in Objective-Smalltalk are 
URIs, resolution of these *Polymorphic Identifiers* is flexible and to a large-extent
user-defined.

A [paper](http://dl.acm.org/citation.cfm?doid=2508168.2508169) introducing Polymorphic Identifiers was presented in October 2013 at the [Dynamic Languages Symposium](http://www.dynamic-languages-symposium.org/dls-13/), part of [SPLASH/OOPSLA 2013](http://splashcon.org/2013/).

The basic idea behind PIs is that identifiers in programming languages designate resources,
but what constitutes a resource has expanded dramatically in the last few decades.  

- Programs include a large number of named file resources, especially iOS and Mac OS X apps
- Many programs nowadays interact with web resources of some sort
- Many in-program resources have non-standard access requirements
- Properties attempt to give resource-style interfaces to state implemented by accessors


Schemes and Scheme Handlers
---------------------------

Instead of being built in to the language, access to resource via identifiers is 
mediated via *scheme handlers*.  Scheme handlers can be either *primitive* 
implementing access to a specific kind of resource, or *composite* combining
other scheme handlers in intersting ways (for example implementing a search
of several scheme handlers or caching the output of one scheme handler using
another).

Once created, scheme handlers are made available to programs by attaching
them to a particular scheme, for example `http`, `file` or `var`.  Scheme
handlers do not have permanent names, but common ones tend to be associated
with specific names:

- `var:` access to program variables 
- `default:` scheme that''s used when no scheme is provided by the program. 
   (Usually `var:`).
- `http:` access to web
- `file:` access to the file system
- `env:` environemnt variables
- `defaults:` Cocoa defaults system
- `class:` Objective-C/Objective-Smalltalk classes
- `bundle:`, `mainbundle:` named resources in the class bundle or the main bundle

Composite schemes include the following:

- *relative* starts at a path within another scheme handler (common: directory)
- *sequential* tries its contained scheme handlers in turns
- *cache* similar to sequential, but writes results in later scheme handlers to first scheme handler
- *filter* filters the names being passed and/or the data read/written
- *sitemap* an in-memory tree of objects

Commonly used schemes are actually composites, for example a user-facing `http:` scheme typically consists
of cache-schemes parametrized with in-memory and relative file schemes in front of the actual raw `http:` scheme.



Parametrized identifiers
------------------------

Compound identifiers can include dynamically evaluated components enclosed in curly brackets.
The identifier `file:{env:HOME}/.bashrc` refers to the `.bashrc` file from the current user''s
home directory.

References
----------

The `ref:` scheme is special in that it doesn''t indicate a specific domain, but rather 
stops evaluation at the reference.  For example. `file:.bashrc` retrieves the contents
of a the `.bashrc`, but `ref:file:.bashrc` returns a reference to that file.  References
are also useful for parametrizing user interface elements, and generally where one would
otherwise be forced to use string keys to refer to parts of objects.


'.

}

}.
