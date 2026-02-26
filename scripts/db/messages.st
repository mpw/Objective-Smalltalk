#!/usr/local/bin/stsh
#-messages


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
  	  classDef := STClassDefinition new.
      classDef setName:table name capitalizedString , 's'.
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


database  := SQLiteScheme alloc initWithPath:  ref:file:{env:HOME}/Library/Messages/chat.db path.
scheme:db ← database.

database createClassForTableNamed: 'message'.

extension Messages {
  -description {
     'A message'.
  }
  -richString { unarchiver ← NSUnarchiver alloc initForReadingWithData:  self attributedBody.  unarchiver decodeObject. }  
  -messageString { self richString string. } 
}.

stdline ! scheme:db.
stdline ! 'did log scheme:db'.
stdout println:'try "db:message count"'
shell runInteractiveLoop.
