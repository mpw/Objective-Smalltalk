#!/usr/local/bin/st
#-<void>runsite:dir
#framework:SiteBuilding load.
dl:Build/obj/libSails.so load 
dl:Build/obj/libObjectiveHTTPD.so load 



stdline ! STSiteServer.

site := STSiteBundle bundleWithPath:dir.
site compileAllSourceFiles.
site setupSite.
server ← site siteServer server.
ref:file:/tmp/mysocket delete.
server setUnixDomainSocketPath:'/tmp/mysocket'.
!chmod a+rw /tmp/mysocket
# server setPort:50001.
server startHttpd ifTrue:{ stdout println:'server started'. } ifFalse:{ stdout println:'server not started'. }.
NSRunLoop currentRunLoop run.

