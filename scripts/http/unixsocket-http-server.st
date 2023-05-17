#!env st
 framework:ObjectiveHTTPD load
server := MPWSchemeHttpServer server
server setScheme: (MPWDictStore storeWithDictionary: #{ #hello: 'World' }).
ref:file:/tmp/mysocket delete.
server server setUnixDomainSocketPath:'/tmp/mysocket'
stdout println: server server socket.
server server startHttpd ifTrue:{ stdout println:'server started'. } ifFalse: { stdout println:'server failed to start'.}.
shell runInteractiveLoop.
