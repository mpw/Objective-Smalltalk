#!env st
#-sqlite:dbpath


scheme SQLiteScheme : SQLiteStore  {


  -<void>setClass:aClass forTable:tableName {
	 (this:tables at:tableName) setTableClass:aClass.
  }

  /. { 
     get {
       self listForNames: this:tables allKeys.
     }
  }

  /schema {
	get { 
		self tables.
	}
  }

  /:table/count { 
     get { (this:tables at: table) count. }
  }

  /:table/:index { 
     get { (this:tables at: table) select | at: index. }
  }

  /:table { 
     get { (this:tables at: table) select. }
  }

  /:table/where/:column/:value { 
     get { (this:tables at: table) selectWhere: "{column} = {value}".  }
  }

  -classDefForTable:table   {
      var classDef := STClassDefinition new.
      classDef setName:table name capitalizedString.
      classDef setSuperclassName: 'NSObject'.
      classDef setInstanceVariableDescriptions: table schema fields.
      classDef.  
  }
  -<void>createClassForTableNamed:name {
      var classDef := self classDefForTable: (this:tables at:name).
	  classDef defineClass.
      self setClass: classDef classToDefine forTable:name.
  }
}.

scheme:db := SQLiteScheme alloc initWithPath: dbpath.
scheme:db do createClassForTableNamed: #('artists', 'albums' ) each.

extension Artists { -description { "Artist: {this:Name} ". }  }
extension Albums { -description { "Album: {this:Title} ". }  }


stdout println:'try "stdout do println: db:artists collect Name each."'.
shell runInteractiveLoop.
