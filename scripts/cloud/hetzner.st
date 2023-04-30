#!env st

scheme:https setHeaders: #{ #Authorization: "Bearer {keychain:password/hetzner-api/metaobject}" }.
scheme:api := ref:https://api.hetzner.cloud/v1 asScheme.

class HetznerHost : MPWRemoteHost {
   var hostDict.
   var serverId.
   +withDictionary:theServer {
	self alloc initWithDictionary:theServer.
   }
   -initWithDictionary:theServer {
       self := super initWithName:(theServer at:'public_net' | at:'ipv4' | at:'ip') user:'root'.
       self setHostDict:theServer.
       self setServerId:self getId.
       self.
     }
     -getId {  self hostDict at:'id'. } 
     -status { self hostDict at:'status'. }
     -actions { api:server/{ivar:serverId}/actions. }
     -liveStatus { id := self getId. api:servers/{id}/status. }
     -<void>refresh {
         id := self getId.
         self setHostDict: (api:servers/{id} value at:'server').
     }
}

class HetznerCloud {
   var api.
   -schemeNames { [ 'api' ]. }
   -servers {
	HetznerHost collect withDictionary: (api:servers at:'servers') each.
   }
}

cloud := #HetznerCloud{ #api: scheme:api }.
shell runInteractiveLoop.
