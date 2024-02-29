
scheme TemplateNames {

    /:id/edit {
       get {
	 'BlogEdit.html'.
       }
    }
    
    /  {
       get {
          'BlogList.html'.
       }
    }
    /new { get {
          'BlogNew.html'.
    } }
    /:id {
       get {
          'BlogEntry.html'.
       }
    }
   /*:p {
       get {
          nil.
       }
    }

}.
