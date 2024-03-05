
scheme TemplateNames {
   var baseName.
    /:id/edit {
       get {
	 "{this:baseName}Edit.html".
       }
    }
    
    /  {
       get {
	 "{this:baseName}List.html".
       }
    }
    /new { get {
           "{this:baseName}New.html".
    } }
    /:id {
       get {
          "{this:baseName}Entry.html".
       }
    }

}
