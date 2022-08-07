#!env st
#-countdockerimages
scheme:docker := MPWJSONConverterStore -> ref:file:/var/run/docker.sock asUnixSocketStore.
docker:/images/json count
