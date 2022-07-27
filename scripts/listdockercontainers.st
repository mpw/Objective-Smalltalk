#!env st
#-ls
dockerbase := MPWUnixDomainHTTPStore alloc initWithSocketPath: '/var/run/docker.sock'
scheme:docker := MPWJSONConverterStore -> dockerbase.
docker:/containers/json
