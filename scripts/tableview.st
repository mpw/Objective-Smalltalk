#!env stui
#-table
class Delegate {
   var items.
   -<int>numberOfRowsInTableView:aTableView { 
	 this:items count.
   }
   -tableView:t objectValueForTableColumn:c row:<int>row {
	this:items at:row | at:c identifier.
   }
   -<double>tableView:aTableView heightOfRow:<int>row {  20.0. }
  -_disabled_tableView:aTableView viewForTableColumn:c row:<int>row {
     NSTextField labelWithString:'hi'.
  }


}.

items := #[ #{ #first: 'Marcel', #last: 'Weiher' }, #{ #first: 'Peter', #last: 'Alexander' }].
delegate ← #Delegate{ #items: items }.

tableview ← #NSTableView{  #dataSource: delegate }.
columns := items firstObject allKeys collect: { :key | 
	 #NSTableColumn{ #width: 150, #identifier: key }.
}.
tableview do addTableColumn: columns each.
tableview inScrollView: (200@400 extent: 500@600).
