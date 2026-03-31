
scheme DynamicSite {
    var bundle.
    var text.
    var md.
    var mdhtml.
    -sitemap {
       stdout print:'-sitemap, rsrc scheme: '.
       stdout println: scheme:rsrc. 
       self.
    }
    -navRootNames {
        [   'About', 'Language'  , 'Publications', 'Download', 'Blog' ].
    }
    -navURLs {
         #{ #Blog: 'https://blog.metaobject.com' }.
    }
    -navItemForName:name active:isActive {
        var url.
        url := '/', name.
        var alternate.
        alternate := self navURLs at:name.
        alternate ifNotNil:{ url := alternate. }.
        var activeClass.
        activeClass := isActive ifTrue:{' class=''active'' ' . } ifFalse:{ ''. }.
        "<li><a  {activeClass} href='{url}'>{name}</a></li>".
    }
    -nav:path {
         var urls.
         urls := self navURLs.
         urls.
         var nb.
         nb := MPWByteStream stream.
         self navRootNames do: { :name | 
             nb writeString: (self navItemForName:name active:false).
         }.
         var navItems.
         navItems := nb target stringValue.
         " <nav>
   <div class='nav-container'>
        <div class='nav-logo'>
            <a href='/'><img src='objst.png'></a>
        </div>
        <ul class='nav-links'>
             {navItems}
       </ul>
     </div>
  </nav>
" .
    }

    -<void>setupSite {
	self.
    }
    -schemeNames { [ 'text', 'md', 'mdhtml' ]. }
    -<void>setRenderer:aRenderer {
       stdout print:'-setRenderer:, rsrc scheme: '.
       stdout println: scheme:rsrc. 
	self setMd: #MPWExtensionStore{ #extension: 'md', #source: scheme:rsrc }.
        self setMdhtml: #MPWBlockFilterScheme{ #source: (self md), #valueFilter: { :md | md markdownToHtml. } }.
        self.
    }
    -createTemplater {
       stdout print:'-createTemplater:, rsrc scheme: '.
       stdout println: scheme:rsrc. 
	self.
    }
    -escape:string {
	string := string stringByReplacingOccurrencesOfString:'<' withString:'&lt;'.
	string := string stringByReplacingOccurrencesOfString:'>' withString:'&gt;'.
	string.
    }
    -inPage:html path:path {
        var pageHtml.
        pageHtml ← nil.
        html ifNotNil: {
           var templater.
	   templater := MPWByteStream stream.
           var env.
	   env := #{ #body: html, #nav:(self nav:path)}.
	   templater writeInterpolatedString: rsrc:pageTemplate.html stringValue withEnvironment:env.
	   pageHtml ← templater target.
        }.
        pageHtml.
    }
    /Publications  { |= { 
         pubs := mdhtml:Publications mutableCopy.
         acm := rsrc:acmrefs.html.
         pubs appendData:acm.
         self inPage: pubs  path:'Publications'.
    } }
    -base:p { 
         stdout print:'GET '; println:p.
         var path.
         path := (p length = 0) or:(p='/') |  ifTrue: {
             'mainPage'.
         } ifFalse: {
              p.
	 }.
         var result.
         result := ''.
         var html.
         html := rsrc:{path}.
         var md.
         md := md:{path} .
         html ifNil:{
            html := self inPage: mdhtml:{path} path:path.
         }.
         var resource.
         resource := html.
	 
         resource ifNotNil:{ result := resource. }.
         stdout print:'result: '; println:result stringValue length.
         result.
    }
    /*:p { |= {
        var path.
        path := p path.
        stdout println:path.
        p := path path.
        (p hasSuffix:'ico' ) ifTrue: {
           nil. 
          } ifFalse: {
              p = '/Publications' ifTrue: { 
                  self Publications. 
              } ifFalse: {
                 self base:p. 
              }.
          }.
        }
     }

     +testSample {
          3.
    }
    +testSelectors {
       [ 'testSample' ]
    }
}
