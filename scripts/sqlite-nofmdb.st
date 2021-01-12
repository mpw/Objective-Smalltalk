#!/usr/local/bin/stsh
#-sqlite:dbpath

extension NSString {
  -relativePathComponents {
 	 #( self ).
  }
}

class ColumnInfo {
	var name.
	var type.
    -description {
		"Column: {var:self/name} type: {var:self/type}".
    }
}

class TableInfo  {
	var name.
	var columns.
    -description {
		cd := self columns description.
        "Table {var:self/name} columns: {cd}".
    }
}

scheme SQLiteScheme  {
  var db.
  var table2class.

  -initWithPath: dbPath {
     self setDb:(MPWStreamQLite alloc initWithPath:dbPath).
     self db open.
     self setTable2class: NSMutableDictionary dictionary.
     self.
  }

  -<void>setClass:aClass forTable:tableName {
     self table2class setObject:aClass forKey:tableName.
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
       resultSet := self objectsForQuery: 'select name from sqlite_master where [type] = "table" '.
       names := resultSet collect objectForKey:'name'.
       names := names, 'schema'.
       self listForNames:names.
     }
  }


  /schema/:table {
     |= {
        resultSet := self objectsForQuery: "PRAGMA table_info({table})".
	    columns := resultSet collect: { :colDict | 
            #ColumnInfo{
				#name : (colDict at:'name') ,
				#type : (colDict at:'type')
			}.
        }.
        #TableInfo{ #name : table, #columns : columns }.
     }
  } 

  /schema {
	|= { 
		self tables.
	}
  }

  /:table/count { 
     |= { self objectsForQuery: "select count(*) from {table}" | firstObject | at:'count(*)'. }
  }

  /:table/:index { 
     |= { self objectsForQuery: "select * from {table}" table:table | at: index. }
  }

  /:table { 
     |= { self objectsForQuery: "select * from {table}" table:table. }
  }

  /:table/:column/:index { 
     |= { self objectsForQuery: "select * from {table}" | at: index.  }
  }

  /:table/where/:column/:value { 
     |= { self objectsForQuery: "select * from {table} where {column} = {value}".  }
  }

  /:table/column/:column { 
     |= { self objectsForQuery: "select {column} from {table}"| collect | at:column. } 
  }
  -tables {
	 content := self:. contents.
	 paths := content collect path.
	 paths := self:. contents collect path.
	 paths collect: { :table | self:schema/{table}. }.
  }
  -<void>logTables {
     stdout do println: self tables each.	
  }
  -classForTable:tableInfo  {
  	  classDef := MPWClassDefinition new.
      classDef setName: tableInfo name capitalizedString.
      classDef setSuperclassName: 'NSObject'.
	  columns := tableInfo columns collect: { :oldColumn | 
			newName := oldColumn name.
			newInfo := ColumnInfo new.
			newInfo setName: newName.
            newInfo.
	  }.
      classDef setInstanceVariableDescriptions: columns.
      classDef.  
  }
}

extension NSObject {
	-initWithDictionary:aDict {
		aDict allKeys do:{ :key |
			self setValue: (aDict at:key) forKey:key.
		}.
		self.
	}
}


scheme:db := SQLiteScheme alloc initWithPath: dbpath.

artistsTable :=  scheme:db tables | at: 2
artistsClass :=  scheme:db classForTable:artistsTable.
stdout println: artistsClass name.
artistsClass defineClass.
scheme:db setClass:Artists forTable:'artists'.

extension Artists { -description { name:=self Name. "Artist: {name} ". }  }

2.

stdout println:'try "stdout do println: db:artists collect Name each."'.
shell runInteractiveLoop.
