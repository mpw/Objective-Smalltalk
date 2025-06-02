#!env st
#-<void>listdirs:<ref>dir

filter counter {
   var count.
   |{  this:count ←1 + this:count. (this:count mod: 1000) = 0 ifTrue:{ ^this:count. }. }
}

(( dir directoryStream) → counter →  #MPWPrintLiner{} → stdout ) run
