#!env stui
#-<void>table:<ref>json
j := #MPWJSONConverterStore{ mutable: true }  → scheme:file
a ← j at:json.
table ← MPWDictArrayTable alloc initWithArray: a.
tableview ← #MPWTableView{ table: table }.
app runFromCLI:(tableview inScrollView:(200@400 extent: 500@600)).
stdout do println: table objects each.
