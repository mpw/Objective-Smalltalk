#!env st
#-<void>countdirs:<ref>dir
(( dir directoryStream) → #MPWCountingFilter{ autoFlush: 1000 }  → stdline ) run
