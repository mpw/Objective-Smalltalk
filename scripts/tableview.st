#!env stui

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


tableview ← #NSTableView{  #frame:(10@45 extent:380@550), #dataSource: delegate }.
columns := items firstObject allKeys collect: { :key | 
	 #NSTableColumn{ #width: 150, #identifier: key }.
}.
stdout println: columns.
tableview do addTableColumn: columns each.
sv ← #NSScrollView{ #frame:(10@45 extent:380@550), #documentView: tableview  }.
window ← #NSWindow{ #frame:(300@700 extent:400@605),#title:'table', #views:#[sv]}.
app runFromCLI:window.
