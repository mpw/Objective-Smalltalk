#!env stui

class Delegate {
  var items.
  -<int>numberOfRowsInTableView:aTableView {  items count. }
  -<double>tableView:aTableView heightOfRow:<int>row {  20. }
  -tableView:aTableView viewForTableColumn:c row:<int>row {
     NSTextField labelWithString: items[row].
  }
}.

delegate ← Delegate new.
delegate setItems: #[ 'First', 'Second' ].

tableview ← #NSTableView{  #frame:(10@45 extent:380@550), #delegate: delegate }.
column ← #NSTableColumn{ #width: 200  }
tableview addTableColumn: column.
sv ← #NSScrollView{ #frame:(10@45 extent:380@550), #documentView: tableview  }.
window ← #NSWindow{ #frame:(300@700 extent:400@605),#title:'table', #views:#[sv]}.
app runFromCLI:window.
