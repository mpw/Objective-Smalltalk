#!env stui
#-<void>table:<ref>json
j := #MPWJSONConverterStore{ mutable: true }  → scheme:file
a ← j at:json.
table ← #MPWTableView{dicts:(a)}.
app runFromCLI:(table inScrollView:(200@400 extent: 500@600)).
stdout do println: table objects each.
