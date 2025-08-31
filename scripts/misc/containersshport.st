#!env st
#-ls:id
scheme:docker := MPWJSONConverterStore -> ref:file:{env:HOME}/.docker/run/docker.sock asUnixSocketStore.
ports := docker:/containers/{id}/json at:'NetworkSettings' | at:'Ports'.
ssh := ports at:'22/tcp' | firstObject.
ssh at:'HostPort'.
