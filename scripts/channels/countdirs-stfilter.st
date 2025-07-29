#!env st
#-<void>listdirs:<ref>dir
filter counter {
   var count.
   -initWithTarget:aTarget {
      self ← super initWithTarget:aTarget.
      this:count ← 0.
      self.
   }
   |{ this:count ← this:count + 1. }
   -<void>close {
      this:target ! count.
   }
   -<int>closeWhenDone { 1. }
}
(( dir directoryStream) → counter → stdline ) run
