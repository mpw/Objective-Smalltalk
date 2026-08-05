#!env stui
#-<void>table:<ref>csv
table ← MPWDelimitedTable alloc initWithData: csv value.
tableview ← #MPWTableView{ table: table }.
tableview reloadData.
app runFromCLI:(tableview inScrollView:(200@400 extent: 500@600)).
stdout do println: table objects each.
