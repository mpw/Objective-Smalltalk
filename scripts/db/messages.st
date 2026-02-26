#!/usr/local/bin/stsh
#-messages


scheme SQLiteScheme  {
  var db.
  var tables.

  -initWithPath: dbPath {
     this:db := (MPWStreamQLite alloc initWithPath:dbPath).
     stdline ! 'before open'.
     openError ← this:db open.
     stdline ! openError.
     stdline ! 'after open did it error'.
     this:tables := this:db tables.
     stdline ! 'after getting tables'.
     stdline ! this:tables.
     self.
  }

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
  	  classDef := STClassDefinition new.
      classDef setName:table name capitalizedString.
      classDef setSuperclassName: 'NSObject'.
      classDef setInstanceVariableDescriptions: table schema.
      classDef.  
  }
  -<void>createClassForTableNamed:name {
      classDef := self classDefForTable: (this:tables at:name).
	  classDef defineClass.
      self setClass: classDef classToDefine forTable:name.
  }
}.
stdline ! 'before'.

scheme:db := SQLiteScheme alloc initWithPath:  '/Users/marcel/Library/Messages/chat.db'

stdline ! 'after'.

stdline ! scheme:db.
stdout println:'try "stdout do println: db:artists collect Name each."'.
shell runInteractiveLoop.
