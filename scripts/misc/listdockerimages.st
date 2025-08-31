#!env st
#-ls
scheme:docker := MPWJSONConverterStore -> ref:file:{env:HOME}/.docker/run/docker.sock asUnixSocketStore.
docker:/images/json
