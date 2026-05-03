
scheme DynamicSite {
    var bundle.
    var text.
    var md.
    var mdhtml.
    -initWithBundle: aBundle {
      self ← super init.
      stdout print:'-sitemap, rsrc scheme: '.
      stdout println: scheme:rsrc. 
      this:bundle ← aBundle.
      self setMd: #MPWExtensionStore{ #extension: 'md', #source: scheme:rsrc }.
      self setMdhtml: #MPWBlockFilterScheme{ #source: (self md), #valueFilter: { :md | md markdownToHtml. } }.
      self.
    }
    -sitemap {
       self.
    }
    -navRootNames {
        [   'About', 'Language'  , 'Publications', 'Download', 'Blog' ].
    }
    -navURLs {
         #{ #Blog: 'https://blog.metaobject.com' }.
    }
    -navItemForName:name active:isActive {
        var url := '/', name.
        var alternate := self navURLs at:name.
        alternate ifNotNil:{ url := alternate. }.
        var activeClass := isActive ifTrue:{' class=''active'' ' . } ifFalse:{ ''. }.
        "<li><a  {activeClass} href='{url}'>{name}</a></li>".
    }
    -nav:path {
         var urls := self navURLs.
         var nb := MPWByteStream stream.
         self navRootNames do: { :name | 
             nb writeString: (self navItemForName:name active:false).
         }.
         var navItems := nb target stringValue.
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
        var pageHtml ← nil.
        html ifNotNil: {
           var templater := MPWByteStream stream.
           var env := #{ #body: html, #nav:(self nav:path)}.
	   templater writeInterpolatedString: rsrc:pageTemplate.html stringValue withEnvironment:env.
	   pageHtml ← templater target.
        }.
        pageHtml.
    }
    /Publications  { get  { 
         var pubs := mdhtml:Publications mutableCopy.
         var acm := self bundle resources at:'acmrefs.html'.
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
         var result := ''.
         var html := rsrc:{path}.
         var md := md:{path} .
         html ifNil:{
            html := self inPage: mdhtml:{path} path:path.
         }.
         var resource := html.
	 
         resource ifNotNil:{ result := resource. }.
         stdout print:'result: '; println:result stringValue length.
         result.
    }
    /*:p { |= {
        var path := p path.
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
