#!env st
#-countdockerimages
scheme:docker := MPWJSONConverterStore -> ref:file:/var/run/docker.sock asUnixSocketStore.
stdout println:'example: docker:/images/json count'.
shell runInteractiveLoop.
