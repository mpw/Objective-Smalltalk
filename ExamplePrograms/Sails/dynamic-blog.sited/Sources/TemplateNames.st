
scheme TemplateNames {

    /:id/edit {
       get {
	 'BlogEdit.html'.
       }
    }
    
    /  {
       get {
	  stdout println:'get root path'.
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
          'BlogList.html'.
       }
    }

}.
