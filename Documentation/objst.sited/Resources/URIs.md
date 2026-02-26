URIs
====

If you've looked at some of the samples, you may have noticed that Objective-Smalltalk fully supports
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
