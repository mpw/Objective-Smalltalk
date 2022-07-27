#!env st
#-ls
scheme:docker := MPWUnixDomainHTTPStore alloc initWithSocketPath: '/var/run/docker.sock'
docker:/containers/json
