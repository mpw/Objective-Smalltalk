#!env st

scheme:https setHeaders: #{ #Authorization: "Bearer {keychain:password/hetzner-api/metaobject}", #Content-Type: 'application/json' }.
scheme:api := ref:https://api.hetzner.cloud/v1 asScheme.

class HetznerHost : MPWRemoteHost {
   var hostDict.
   var id.
   var server.

   +withDictionary:theServer {
	self alloc initWithDictionary:theServer.
   }
   -initWithDictionary:theServer {
       self := super initWithName:(theServer at:'public_net' | at:'ipv4' | at:'ip') user:'root'.
       self setHostDict:theServer.
       self setId: theServer['id'].
       self setServer: ref:api:/servers/{this:id} asScheme.

       self.
     }
     -schemeNames { ['server']. }
     -status { this:hostDict at:'status'. }
     -actions { api:servers/{this:id}/actions value.  }
     -liveStatus { server:status. }
     -metrics { server:metrics. }
     -<void>refresh {
         self setHostDict: (server:/ value at:'server').
     }
     -shutdown {
         ref:server:actions/shutdown post:#{}.
     }
     -start {
         ref:server:actions/poweron post:#{}.
     }
     -reinstall:osName {
         ref:server:actions/rebuild post: #{ #image: osName }.
     }
     -reinstall {
         self reinstall:'ubuntu-20.04'.
     }
     -delete {
         ref:server:/ delete.

     }
}

class HetznerCloud {
   var api.
   -schemeNames { [ 'api' ]. }
   -servers {
	HetznerHost collect withDictionary: (api:servers at:'servers') each.
   }
   -images {
	api:images .
   }
   -types {
	api:server_types .
   }
   -baseDefinition {
	#{ 
	    #location: 'fsn1',
	    #public_net: #{
                #enable_ipv4: true,
                #enable_ipv6: false,
           }
	}.
   }
   -intelServerDefinition {
	#{
           #name:  'objst-2',
           #image: '67794396',
           #ssh_keys: ['marcel@naraht.local' ],
           #server_type: 'cx11',
	} , self baseDefinition.
   }
   -armServerDefinition {
	#{
           #name:  'objst-2',
           #image: '103908070',
           #ssh_keys: ['marcel@naraht.local' ],
           #server_type: 'cax11',
	} , self baseDefinition.
   }
   -create {
	ref:api:servers post: self armServerDefinition  asJSON.
   }
   -createIntel {
	ref:api:servers post: self intelServerDefinition asJSON.
   }
}

cloud := #HetznerCloud{ #api: scheme:api }.
shell runInteractiveLoop.
