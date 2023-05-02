#!env st

scheme:https setHeaders: #{ #Authorization: "Bearer {keychain:password/hetzner-api/metaobject}", #Content-Type: 'application/json' }.
scheme:api := ref:https://api.hetzner.cloud/v1 asScheme.

class HetznerHost : MPWRemoteHost {
   var hostDict.
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
     -actions { api:servers/{this:id}/actions value.  }
     -liveStatus { api:servers/{this:id}/status. }
     -metrics { api:servers/{this:id}/metrics. }
     -<void>refresh {
         self setHostDict: (api:servers/{this:id} value at:'server').
     }
     -shutdown {
         ref:api:servers/{this:id}/actions/shutdown post:#{}.
     }
     -start {
         ref:api:servers/{this:id}/actions/poweron post:#{}.
     }
     -reinstall:osName {
         ref:api:servers/{this:id}/actions/rebuild post: #{ #image: osName }.
     }
     -reinstall {
         self reinstall:'ubuntu-20.04'.
     }
     -delete {
         ref:api:servers/{this:id} delete.

     }
}

class HetznerCloud {
   var api.
   -schemeNames { [ 'api' ]. }
   -servers {
	HetznerHost collect withDictionary: (api:servers at:'servers') each.
   }
   -types {
	api:server_types .
   }
   -serverDefinitionDict {
	#{
           #name:  'objst-2',
           #ssh_keys: ['ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQDLxAUKndzZU56wXTznGcz9rcaxl0qnQ+0hBaVkBHihxMOjW4adgVKwP4NHO10dGJdLj8imjICzqw+5j0iYDsGVx8Ibh99kfN+RmMOZZH4k8xb94PgMaMPOhkxM/w5K/MW9u6lajxavvdvBvEw4qtuINF1sFJs3gb0xSADpR0bohYkYXF/eLCL4dnh7PFitLI1h8kIh3AVfHdTcEVBtuZ4VXDTyrl0Dkeccu6B0Kxnq4fxSXz3jzstZlFsO2Bb9EIlxiv/uqms630/ijvwdal+IVwLyTRcx7m/4MDGyaXytjoRxRBl4TI9aeiq/OI3m0T4sAVX5q4UlZ6yLz3uDbt4O3wCBuxE8GMJmS9XaJLRl1vkIqc/6C8PoD1KsaJRaxggVk/tgm7js5jqRcqVdjHfG7hq1sls/pnrA6conGfxR/Zvjufr+H/Q+2lNKXNoMkUjW9/Esii+ERFSBZiTq2RIIWcPypiBJawjICd9tLcnaFegw1aAIYULF1YINJGqfZNU= marcel@naraht.local'],
           #architecture: 'arm',
           #server_type: 'cax11',
           #location: 'fsn1',
           #public_net: #{
                #enable_ipv4: true,
                #enable_ipv6: false,
           }
	}.
   }
   -create {
	ref:api:servers post: self serverDefinitionDict.
   }
}

cloud := #HetznerCloud{ #api: scheme:api }.
shell runInteractiveLoop.
