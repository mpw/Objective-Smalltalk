#!env stui
#-<void>array
field ← #TextField{frame:(180@24) }.
filter Empty |{ ^object. }.
empty ← #Empty{}.
field → empty.
app runFromCLI:field.
stdout println: empty target.

