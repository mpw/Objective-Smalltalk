#!env st
#-ls

stdout println:'top'.
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
#stdout println:imgJson.
ids := imgJson collect at:'Id'.
stdout println:ids.
names := ids collect:{ :theId |
	aName := docker:image/{theId}/name.
	stdout println:aName.
	aName.
}.
stdout println:names.
