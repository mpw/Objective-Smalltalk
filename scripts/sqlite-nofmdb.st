#!/usr/local/bin/stsh
#-sqlite:dbpath


extension NSString {
  -relativePathComponents {
 	 #( self ).
  }
}.

class TableInfo  {
	var name.
	var columns.
    -description {
		cd := self columns description.
        "Table {this:name} columns: {cd}".
    }
}.


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

  -objectsForQuery:query class:aClass {
     builder := MPWPListBuilder builder.
     aClass ifNotNil: { builder := MPWObjectBuilder alloc initWithClass:aClass. }.
	 self db setBuilder:builder.
     self db query:query.
	 result := self db builder result.
#     stdout println:result.
     result.
  }

  -objectsForQuery:query table:aTableName {
      self objectsForQuery:query class: (self table2class objectForKey:aTableName).
  }

  -objectsForQuery:query  {
      self objectsForQuery:query class: nil.
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

  -<void>logTables {
     stdout do println: self tables allValues each.	
  }
  -classForTable:table   {
  	  classDef := MPWClassDefinition new.
      classDef setName:table name capitalizedString.
      classDef setSuperclassName: 'NSObject'.
	  columns := table schema collect: { :oldColumn | 
			newName := oldColumn name.
			newInfo := MPWSQLColumnInfo new.
			newInfo setName: newName.
            newInfo.
	  }.
      classDef setInstanceVariableDescriptions: columns.
      classDef.  
  }
}.

extension NSObject {
	-initWithDictionary:aDict {
		aDict allKeys do:{ :key |
			self setValue: (aDict at:key) forKey:key.
		}.
		self.
	}
}.


scheme:db := SQLiteScheme alloc initWithPath: dbpath.

artistsTable :=  scheme:db tables at:'artists'.
artistsClass :=  scheme:db classForTable:artistsTable.
stdout println: artistsClass name.
artistsClass defineClass.
scheme:db setClass:Artists forTable:'artists'.

extension Artists { -description { name:=self Name. "Artist: {name} ". }  }


stdout println:'try "stdout do println: db:artists collect Name each."'.
shell runInteractiveLoop.
