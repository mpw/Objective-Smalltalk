#!env stui
#-<void>table:<ref>json
j := #MPWJSONConverterStore{ mutable: true }  → scheme:file
a ← j at:json.
a firstObject at:'first' put:'Hello'.
table ← #MPWTableView{items:(a)}.
app runFromCLI:(table inScrollView:(200@400 extent: 500@600)).
stdout do println: table items each.
