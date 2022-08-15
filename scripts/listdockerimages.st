#!env st
#-ls
scheme:docker := MPWJSONConverterStore -> ref:file:/var/run/docker.sock asUnixSocketStore.
docker:/images/json
