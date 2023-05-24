#!env stui
#-<void>table:<ref>json
j := MPWJSONConverterStore → scheme:file
table ← #MPWTableView{#items:(j at:json)}.
app runFromCLI:(table inScrollView:(200@400 extent: 500@600)).
stdout do println: table items each.
