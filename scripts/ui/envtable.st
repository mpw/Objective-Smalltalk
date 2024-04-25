#!env stui
#-<void>envtable
table ← #MPWTableView{items: env:. dicts }.
app runFromCLI:(table inScrollView:(200@400 extent: 500@600)).
