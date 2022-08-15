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
   /imagesRaw { |= {
	this:source at:'/images/json'.
    }
   }
   /images { |= {
	json := this:source at:'/images/json'.
	ids := json collect at:'Id'.
	ids collect: { :id |
	   self:image/{id}/name.
	}.
    }
   }
}.

base := MPWJSONConverterStore -> ref:file:/var/run/docker.sock asUnixSocketStore.
#base := ref:file:/var/run/docker.sock asUnixSocketStore.
scheme:docker := Docker alloc initWithBase:base.
stdout do println: docker:images each.
