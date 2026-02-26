About Objective-Smalltalk
==============

Objective-Smalltalk is an architecture-oriented programming language based loosely on Smalltalk and Objective-C.
It currently runs on macOS, iOS and Linux, the latter using GNUstep.  

By allowing general architectures, Objective-Smalltalk is the first general purpose programming language.

What we currently call general purpose languages are actually domain specific languages for the
domain of algorithms.

Objective-Smalltalk includes an Objective-C compatible runtime model, but using a much simpler and consistent
Smalltalk-based syntax. Unlike Smalltalk, Objective-Smalltalk has syntax for defining classes and so can
be file-based and is "vi-hackable".



Why Objective-Smalltalk?
------------------------

Software development is too hard.  As Alan Kay put it: [code seems "large" and "complicated" for what it does](https://youtu.be/ubaX1Smg6pY?t=126).

Much of this difficulty is due to architectural-mismatch: although we know some good architectural 
styles for software, those architectural are difficult to use, because they clash with the call/return 
architectural style imposed by our programming languages.

This mismatch means that although we can _build_ good architectures, we cannot _express_ them
directly in code.  And as this inability is caused by our abstraction mechanisms, our [usual technique](https://en.wikipedia.org/wiki/Indirection) of adding one abstraction layer does not actually help, but just adds
layers of indirection.

Software Architecture
-----------------------------

The theoretical foundation for Objective-Smalltalk is Mary Shaw's [Procedure Calls Are the Assembly Language of Software Interconnection: Connectors Deserve First-Class Status](https://resources.sei.cmu.edu/library/asset-view.cfm?assetid=12137). 

Objective-Smalltalk makes available mechanisms to define architectural styles via connector and component
definitions, and comes with a library of such styles, supported by syntax that makes it possible to
directly express systems in those styles.  The styles currently supported are:

1. OO and Call/Return

    This is probably the most conventional style, with classes, instances, messages and message
    expressions, methods and interfaces.

    It is enhanced with Higher Order Messaging.

2. (OO) Pipes and Filters 

    This style is dataflow-oriented, based on Unix Pipes and Filters.  It features filter components that
    send and receive objects, organized in pipelines.  

    It is highly compositional and vastly vastly simplifies both asynchronous programming tasks and
    error handling.

    It is adapted bi-directionally to Unix Pipes and Filters:  Unix filters can be easily used from OO 
    filters and OO filters are easily used in Unix pipelines.


3. (In-Process) REST

    This style is an adaptation of the REST architectural style of the WWW to use in-process that
    is supported by _Storage Combinators_, composable (virtual) storage elements, and 
    _Polymorphic Identifiers_, a URI-like extension of identifiers.

    Software that includes a storage component can be simplified dramatically using Storage Combinators
    and Polymorphic Identifiers.

    Storage Combinators are adapted bi-directionally to HTTP: reading and writing HTTP resources via
    Polymorphic Identifiers is trivial, as is seerving Storage Combinators via HTTP.

4. Implicit Invocation / Event Broadcast

    Many achitectural styles rely on event broadcasts, for example to notify subscribers that
    a resource has changed.  


These styles interact with each other synergistically and are provided to increase expressive
power and ease construction.  Conformance to specific styles is not enforced by restrictions,
but encouraged by providing useful libraries.




Objective-C without the C
----------------------------------

Objective-Smalltalk is built on top of the Objective-C runtime, as a peer to 
Objective-C and other languages. It uses the host platform's C ABI.
It dose not require a VM.

Where Objective-C is C with Smalltalk extensions, Objective-Smalltalk is  
Smalltalk with C extensions and the (Objective-)C runtime model.



Why not Swift?
--------------------

While Swift fixes some of Objective-C's most obvious flaws that were due to it being
constructed by crashing two existing languages into each other, it discards the good 
with the bad.  With a vengeance.

Objective-Smalltalk also discards the bad, while enhancing the good and taking it to an
entirely new level.



