#!env st
#-<void>ls


scheme Docker {
   var source.
   -init {
      this:source := (MPWJSONConverterStore -> ref:file:/var/run/docker.sock asUnixSocketStore).
      self.
   }
   -schemeNames {
      [ 'source' ].
   }
   /image/:id/name { |= {
	dict := source:/images/{id}/json.
	name := dict at:'RepoTags' | firstObject.
	name isNotNil ifTrue:{ name.} ifFalse:{ ''. }.
    }
   }
   /images { |= {
	json := source:/images/json.
	json collect: { :dict |
	   id := dict['Id'].
	   self:image/{id}/name.
	}.
    }
   }
}.

scheme:docker := Docker new.
stdout do println: docker:images each.
