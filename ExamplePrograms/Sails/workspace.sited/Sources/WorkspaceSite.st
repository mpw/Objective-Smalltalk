scheme WorkspaceSite {
    var bundle.
    var lastResult.
    var lastCode.

    -initWithBundle:aBundle {
        this:bundle := aBundle.
        this:lastResult := ''.
        this:lastCode := '3 + 4'.
        self.
    }

    -init {
        self initWithBundle:nil.
    }

    -interpreter {
        this:bundle interpreter.
    }

    -evaluateCode:code {
        this:lastCode := code.
        result := self interpreter evaluateScriptString:code.
        this:lastResult := result isNil ifTrue:{ 'nil' } ifFalse:{ result stringValue }.
        this:lastResult.
    }

    -at:ref post:data {
        code := data at:'code' | stringValue.
        self evaluateCode:code.
        self renderPage.
    }

    -escapeHtml:string {
        result := string.
        result := result stringByReplacingOccurrencesOfString:'&' withString:'&amp;'.
        result := result stringByReplacingOccurrencesOfString:'<' withString:'&lt;'.
        result := result stringByReplacingOccurrencesOfString:'>' withString:'&gt;'.
        result.
    }

    -renderPage {
        template := this:bundle resources at:'Workspace.html' | stringValue.
        template := template stringByReplacingOccurrencesOfString:'{code}' withString:(self escapeHtml:this:lastCode).
        template := template stringByReplacingOccurrencesOfString:'{result}' withString:(self escapeHtml:this:lastResult).
        template dataUsingEncoding:4.
    }

    / {
        get {
            self renderPage.
        }
    }

    /*:path {
        get {
            "<html><body>Unknown path: {path}. <a href='/'>Go to workspace</a></body></html>" asData.
        }
    }
}
