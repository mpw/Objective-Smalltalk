#!env stsh
framework:SchemeFUSE load.

scheme clock {
	/date {  |= {
		stdout println:'checking the date!'.
		#NSDate{} stringValue lf.
	} }
	-childrenOfReference:aRef  {
		#[ 'date' ].
	}
	-<int>hasChildren:aRef {
		aRef path = '/'.
	}
}.


scheme:txt := #MPWExtensionMapper{ #extension: 'txt' , #source: (clock store) }


fs := scheme:txt  mountAt: '/Volumes/clock'.

shell runInteractiveLoop.

fs unmount.
