#!env st
#-ls

stdout println:'top'.
scheme Docker {
   var source.
   -initWithBase:newbase {
      this:source := newbase.
      self.
   }
   /images { |= {
	this:source at:'/images/json'.
    }
   }
}.

#base := MPWJSONConverterStore -> ref:file:/var/run/docker.sock asUnixSocketStore.
base := ref:file:/var/run/docker.sock asUnixSocketStore.
scheme:docker := Docker alloc initWithBase:base.
stdout println: scheme:docker source.
docker:images.
