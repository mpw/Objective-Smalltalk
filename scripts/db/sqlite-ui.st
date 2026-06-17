#!env stui
#-sqlite:tableName


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
      var schema ← table schema.
      schema setName: classDef name.
      classDef setStructureDefinition: schema.
      classDef.  
  }
  -<void>createClassForTableNamed:name {
      var classDef := self classDefForTable: (this:tables at:name).
      stdline ! classDef.
      classDef defineClass.
      self setClass: classDef classToDefine forTable:name.
  }
  -<void>didSelect: tableItem {
      var tableName ← tableItem['name'].
      var table ←  self at:tableName.
      stdline ! table columns.
      var tableView ← #MPWTableView{ table: table  }.
      tableView reloadData.
      tableView inScrollView:(200@400 extent: 500@600) | openInWindow:tableName.
  }
}.

scheme:db := SQLiteScheme alloc initWithPath: 'chinook.db'.
scheme:db do createClassForTableNamed: #('artists', 'albums' ) each.

extension Artists { -description { "Artist: {this:Name} ". }  }
extension Albums { -description { "Album: {this:Title} ". }  }

tables ← scheme:db tables allKeys.
tables ← tables collect:{ :name |  #{ name: name }. }.

tablesTable ← MPWDictArrayTable alloc initWithObjects: tables. 
stdline ! 'tables:'.
stdline ! tablesTable.
stdline ! 'now the table view'.
tableView ← #MPWTableView{ table: tablesTable  }.
stdline ! 'got the table view'.
stdline ! tableView. 

tableView reloadData.

tableView setMpwDelegate: scheme:db.


app runFromCLI:(tableView inScrollView:(200@400 extent: 500@600)).
