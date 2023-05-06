#!env st

scheme:https setHeaders: #{ #Authorization: "Bearer {keychain:password/digital-ocean-api/metaobject}", #Content-Type: 'application/json' }.
scheme:api := ref:https://api.digitalocean.com/v2/ asScheme.

class DODroplet : MPWRemoteHost {
   var id.
   var hostDict.
   var droplet.

   +withDictionary:theServer {
	self alloc initWithDictionary:theServer.
   }
   -initWithDictionary:theServer {
       self := super initWithName:( theServer at:'networks' | at:'v4' | firstObject | at:'ip_address')  user:'root'.
       self setHostDict:theServer.
       self setId: theServer['id'].
       self setDroplet: ref:api:/droplets/{this:id} asScheme.

       self.
     }
     -schemeNames { ['droplet']. }
     -status { this:hostDict at:'status'. }
     -actions { droplet:actions value.  }
     -liveStatus { droplets:status. }
     -metrics { droplet:metrics. }
     -fetchDropletDict {
	droplet:/ .
     }
     -<void>refresh {
         self setHostDict: (droplet:/ value at:'server').
     }
     -shutdown {
         ref:droplet:actions/shutdown post:#{}.
     }
     -start {
         ref:droplet:actions/power_on post:#{}.
     }
     -reinstall:osName {
         ref:droplets:actions/rebuild post: #{ #image: osName }.
     }
     -reinstall {
         self reinstall:'ubuntu-20.04'.
     }
     -delete {
         ref:droplet:/ delete.

     }
}

class DigitalOcean {
   var api.
   -schemeNames { [ 'api' ]. }
   -servers {
        api:droplets.
   }
   -serverObjects {
	DODroplet collect withDictionary: (api:droplets value at:'droplets') each.
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
           #image: '129211873',
           #ssh_keys: [ ],
           #size:    's-1vcpu-1gb',
	}.
   }
   -create {
	ref:api:droplets post: self intelServerDefinition asJSON.
   }
}

cloud := #DigitalOcean{ #api: scheme:api }.
shell runInteractiveLoop.
