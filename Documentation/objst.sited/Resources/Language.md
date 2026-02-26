## Language


Objective-Smalltalk is an architectural construction language that superfically resembles a revamped Smalltalk. 

It makes most parts of the language polymorphic, provides
primitives for the definition of architectural components and
means of connecting these components into systems using
connectors.

#### Connecting

Components can be connected using the right arrow →.

For example, the following will connect a text field you have created (assumed to
be stored in the variable `text`) to `stdout`.

    text → stdout.

The right arrow is polymorphic:  in the previous exampe, it connected the two components via their default in and out ports, which happned to be compatible.

The text field can be created as follows:

    text ← #NSTextField{ #frame: (180@24)  }.

Combining these two lines of code creates a complete program that will show a text field
and echo the user entered text to the console.

#### URIs


Objective-Smalltalk uses URIs as its identifiers. 


    var:name ← 'World'.
    file:hello.txt ← "Hello {name}!".
    file:download.txt ← http://objective.st/. 



#### References

If we don't want the value that is pointed at the by the URI, but the URI instead, we can stop evaluation by getting the reference of the variable.

    ref:file:hello.txt length

References generalize the concept of a pointer.

    a := 4.
    pointer := ref:a.
    pointer value.    (4)
    pointer value:5.
    a.   (5)




#### Scheme Handlers

The extensible nature of 

#### Dataflow constraints

    a |= b.


#### Literals

Numbers:   

    1, 2, 3, 3.0
    1.0 3.4

Strings:
 
     'Hello World'

Interpolated Strings: 

    "Hello {name}"

Arrays:   

    #( 1,2,3,4 )

Dictionaries:   

    #{ #key1 : 'value',  #key2: 42 }



Objects:

    #UILabel{ 
       #text : 'Hello World with more text.',
       #length: 0,
       #font:  font: ,
       #color:  color:system/gray
    }



#### Object templates



    object Body : #UILabel{
       #length: 0,
       #font:  font: ,
       #color:  color:system/gray
    }

    #Body{ 
       #text : 'Hello World with more text.',
     }
    #Body{ 
       #text : 'Some other earth shattering text.',
     }


#### Messages



Like Smalltalk, virtually all of the basics of expressions are handlde by message conneectors, and again like
Smalltalk, Objective-Smalltalk  distinguishes three kinds of messaege:  unary, binary, keyword.

Unary:

    receiver message.

Binary:

    2 * 3.

Keyword:

    'Hello ' stringByAppendingString:'World!'.

The statement separator is the period '`.`'.

Objective-Smalltalk has two mechanisms for chaining muliple messages.  The _cascade_, 
denoted by a semicolon, sends multiple messages to the same receiver:

    receiver msg1;
             msg2;
             msg3.


The pipe  '`|`' evaluates the expression on its right wiith the result of
the message on its left.  This makes messaging consistent with pipelines
and also avoids the need for brackets in many cases.

     a + b | negated.
     'hello' stringByAppendingString:' world!'  | captalizedString.


#### Assignment

The assignment connector uses the left arrow '←', but also accepts the Smalltalk/Pascal convention of ':='.

    a := 2.
    b ← 3.



#### Blocks and Control Structures

Blocks in Objective-Smalltalk use curly brackets.

     { 3+4 }.

Block parameters are separated from the body by the pipe symbol ('|') like in Smalltalk and start with colons:

     { :a :b | a+b }.


As is the case in Smalltalk, control structures are implemented using blocks and plain message sends, for example conditionals, which can be used as expressions.
 
     flag ifTrue: { a:=2 } ifFalse:{ a:=3 }.
     a := flag ifTrue: { 2. } ifFalse:{ 3 }.



#### Classes


Classes are components that correspond to the class construct from other object-oriented languages.

    class Hello : NSObject {
        var someVar.
    }

Superclass can be omitted.  Each kind of component has its own default superclass, in the cases of classes
that superclass is `NSObject`.

    class Hello {
        var someVar.
    }

The scheme-handler definitions we saw earlier are a special kind of class definition.


#### Methods

Method components are defined using a syntax that is closely modeled on Objetive-C, with thee minus sign '-' introducing an instance method definition.
The method body is enclosed in curly braces.  There is no need for a return statement, no return type given means an object is returned.


    class Hello {
       -greet {
            'Hello World!'.
       }
    }

Parameters 

    class Hello {
       -greet:name {
            "Hello {name}!".
       }
    }

Types are enclosed in angle brackets:

    class DeepThought {
       -<int>answer {
            6*7.
       }
    }

#### Filters

Filters define dataflow components similar to Unix filters, but as classes and 
passing objects instead of byte streams.

    filter toupper |{  ^object stringValue uppercaseString. }



#### Protocols

Similar to the way that classes are components that group method components, protocols are compound connectors 
that group message connectors.

    protocol ModelDidChange  { 
          -<void>modelDidChange:ref.
    }

Protocols can be referenced by name:

    protocol:NSObject

This is equivalent to Objective-C's @protocol() expression.


