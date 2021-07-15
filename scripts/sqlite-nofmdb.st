#!/usr/local/bin/stsh
#-sqlite:dbpath


scheme SQLiteScheme  {
  var db.
  var tables.

  -initWithPath: dbPath {
     this:db := (MPWStreamQLite alloc initWithPath:dbPath).
     this:db open.
	 this:tables := this:db tables.
     self.
  }

  -<void>setClass:aClass forTable:tableName {
	 (this:tables at:tableName) setTableClass:aClass.
  }

  /. { 
     |= {
       self listForNames: this:tables allKeys.
     }
  }

  /schema {
	|= { 
		self tables.
	}
  }

  /:table/count { 
     |= { (this:tables at: table) count. }
  }

  /:table/:index { 
     |= { (this:tables at: table) select | at: index. }
  }

  /:table { 
     |= { (this:tables at: table) select. }
  }

  /:table/where/:column/:value { 
     |= { (this:tables at: table) selectWhere: "{column} = {value}".  }
  }

  -classDefForTable:table   {
  	  classDef := MPWClassDefinition new.
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

scheme:db := SQLiteScheme alloc initWithPath: dbpath.
scheme:db do createClassForTableNamed: #('artists', 'albums' ) each.

extension Artists { -description { "Artist: {this:Name} ". }  }
extension Albums { -description { "Album: {this:Title} ". }  }


stdout println:'try "stdout do println: db:artists collect Name each."'.
shell runInteractiveLoop.
