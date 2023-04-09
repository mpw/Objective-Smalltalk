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
	dict:= self:image/{id}/json.
	dict['RepoTags'] firstObject.
    }
   }
   /image/:id { |= {
	source:/images/{id}/json.
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
shell runInteractiveLoop.
