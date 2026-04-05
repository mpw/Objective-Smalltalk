#!env stui
#-<void>table:<ref>json
class Person {
   var first.
   var last.
   -full {
      "{this:first} {this:last}".
   }
   -description { 
      "<Person: {this:first} {this:last}> ".
   }
}.
j := #MPWJSONConverterStore{ mutable: true, converterClass: class:Person }  → scheme:file.
a ← j at:json.
stdline !  a.
table ← #MPWObjectArrayTable{ itemClass: class:Person , objects: a }.
stdline ! table.
fullDef ← #MPWVariableDefinition{ name: 'full', operations: 0 }.
table setItemStructure: (table itemStructure, fullDef ).
tableView ← #MPWTableView{ table: table  }.
app runFromCLI:(tableView inScrollView:(200@400 extent: 500@600)).
stdout do println: table objects each.
