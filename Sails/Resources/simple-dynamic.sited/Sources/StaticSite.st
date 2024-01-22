
scheme StaticSite {
    var bundle.
    /*:p { |= {
         path := p length = 0 ifTrue: { 'index.html'. } ifFalse: { p. }.
         path := p  = '/' ifTrue: { 'index.html'. } ifFalse: { path. }.
         resource := self bundle cachedResources at:path.
         result := path.
         resource ifNotNil:{ result := resource. }.
         result.
       }
    }
}
