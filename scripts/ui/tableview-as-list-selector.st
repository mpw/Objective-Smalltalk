#!env stui
#-<void>selector
a ← [ #{ item: 'first'} , #{ item:  'second' } , #{ item: 'third' }] .
table ← MPWDictArrayTable alloc initWithArray: a.
tableview ← #MPWTableView{ table: table }.
tableview reloadData.

class SelectionChanger { 
   var array.
   -<void>tableViewSelectionDidChange: someInfo {
       var selection ← someInfo['NSTableViewCurrentRowSelectionUserInfoKey'].
       stdout println: 'selection: ', selection.
       var index ← selection firstIndex.
       stdout println: 'index: ', index stringValue.
       var selected ← this:array at:index.

       stdout ! selected.
       
   }
}.
s ← #SelectionChanger{ array: a }.
stdline ! s.
tableview setMpwDelegate: s.

app runFromCLI:(tableview inScrollView:(200@400 extent: 500@600)).
stdout do println: table objects each.
