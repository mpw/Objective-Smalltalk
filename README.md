Objective-Smalltalk
===================

[Objective-Smalltalk](http://objective.st/ "Objective-Smalltalk main site") is a programming
language derived from Smalltalk, Objective-C with significant additions for connector-oriented
programming.

It is still experimental.

Build instructions:
------------

1.  Clone MPWFoundation

    git clone https://github.com/mpw/MPWFoundation.git

2.  Clone ObjectiveSmalltalk

    git clone https://github.com/mpw/Objective-Smalltalk.git

3.  Open Objective-Smalltalk/objective-smalltalk.xcworkspace

4.  Build the 'stsh' scheme 



Raspberry Pi build instructions
-------------

1. Install GNUstep, I used a [build script](https://github.com/plaurent/gnustep-build).
2. Clone both project as above.
3. run  ./makeheaderdir in each of the project directories
4. use make in each of the project directories to build (MPWFoundation first)


These should also work for other Linux systems. For exmaple, the
[Objective-S website](http://objective.st) is served by Objective-S
on Digital Ocean Droplet with Ubuntu.

