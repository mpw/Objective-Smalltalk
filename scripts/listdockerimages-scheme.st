#!env st
#-<void>ls

scheme Docker {
   var source.
   -initWithBase:newbase {
      this:source := newbase.
      self.
   }
   /image/:id/name { |= {
	dict := this:source at:"/images/{id}/json".
	name := dict at:'RepoTags' | firstObject.
	name isNotNil ifTrue:{ name.} ifFalse:{ ''. }.
    }
   }
   /images { |= {
	this:source at:'/images/json'.
    }
   }
}.

base := MPWJSONConverterStore -> ref:file:/var/run/docker.sock asUnixSocketStore.
#base := ref:file:/var/run/docker.sock asUnixSocketStore.
scheme:docker := Docker alloc initWithBase:base.
imgJson := docker:images.
ids := imgJson collect at:'Id'.
names := ids collect:{ :theId |
	aName := docker:image/{theId}/name.
	aName.
}.
names := names select:{ $0 length > 0. }.
stdout do println:names each.
