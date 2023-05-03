#!env st

scheme:https setHeaders: #{ #Authorization: "Bearer {keychain:password/digital-ocean-api/metaobject}", #Content-Type: 'application/json' }.
scheme:api := ref:https://api.digitalocean.com/v2/ asScheme.

class DODroplet : MPWRemoteHost {
   var id.
   +withDictionary:theServer {
	self alloc initWithDictionary:theServer.
   }
   -initWithDictionary:theServer {
       self := super initWithName:(theServer at:'public_net' | at:'ipv4' | at:'ip') user:'root'.
       self setHostDict:theServer.
       self setId: theServer['id'].
       self.
     }
     -status { this:hostDict at:'status'. }
     -actions { api:droplets/{this:id}/actions value.  }
     -liveStatus { api:droplets/{this:id}/status. }
     -metrics { api:droplets/{this:id}/metrics. }
     -<void>refresh {
         self setHostDict: (api:droplets/{this:id} value at:'server').
     }
     -shutdown {
         ref:api:droplets/{this:id}/actions/shutdown post:#{}.
     }
     -start {
         ref:api:droplets/{this:id}/actions/power_on post:#{}.
     }
     -reinstall:osName {
         ref:api:droplets/{this:id}/actions/rebuild post: #{ #image: osName }.
     }
     -reinstall {
         self reinstall:'ubuntu-20.04'.
     }
     -delete {
         ref:api:droplets/{this:id} delete.

     }
}

class DigitalOcean {
   var api.
   -schemeNames { [ 'api' ]. }
   -servers {
	DODroplet collect withDictionary: (api:servers at:'servers') each.
   }
   -images {
	api:images .
   }
   -types {
	api:server_types .
   }
   -intelServerDefinition {
	#{
           #name:  'objst-2',
           #region:  'nyc',
           #image: 'ubuntu-20-04-x64',
           #ssh_keys: ['marcel@naraht.local' ],
           #size:    's-1vcpu-1gb',
           #public_net: #{
                #enable_ipv4: true,
                #enable_ipv6: false,
           }
	}.
   }
   -create {
	ref:api:servers post: self intelServerDefinition asJSON.
   }
}

cloud := #DigitalOcean{ #api: scheme:api }.
shell runInteractiveLoop.
