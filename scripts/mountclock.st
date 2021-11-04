#!env stsh
framework:SchemeFUSE load.

scheme clock {
	/date {  |= {
		#NSDate{} stringValue lf.
	} }
	-childrenOfReference:aRef  {
		#[ 'date' ].
	}
	-<int>hasChildren:aRef {
		aRef path = '/'.
	}
}.

scheme TxtExtension : MPWMappingStore {
    -reverseMapReference:aReference {
        aReference path stringByAppendingPathExtension:'txt'.
    }
    -mapReference:aReference {
        aReference path stringByDeletingPathExtension.
    }
}.

scheme:txt := TxtExtension storeWithSource: clock store.


fs := scheme:txt  mountAt: '/Volumes/clock'.

shell runInteractiveLoop.

fs unmount.
