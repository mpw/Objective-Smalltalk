class Post  {
	var id.
	var title.
	var body.
        -description {
	    "Entry '{this:title}' body '{this:body}'".
        }
        +id:newId {
             new ← self new autorelease.
             new setId:newId.
             new.
        }
}.

